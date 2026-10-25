package com.optimeas.opticloudsensor.connection

import com.hivemq.client.mqtt.MqttGlobalPublishFilter
import com.hivemq.client.mqtt.datatypes.MqttQos
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient
import com.hivemq.client.mqtt.mqtt3.Mqtt3Client
import com.hivemq.client.mqtt.mqtt3.exceptions.Mqtt3ConnAckException
import com.hivemq.client.mqtt.mqtt3.message.connect.connack.Mqtt3ConnAckReturnCode
import com.hivemq.client.mqtt.mqtt3.message.subscribe.Mqtt3Subscribe
import com.hivemq.client.mqtt.mqtt3.message.subscribe.Mqtt3Subscription
import com.hivemq.client.mqtt.mqtt3.message.subscribe.suback.Mqtt3SubAckReturnCode
import com.optimeas.opticloudsensor.core.connection.MqttConnector
import com.optimeas.opticloudsensor.core.connection.MqttEndpoint
import com.optimeas.opticloudsensor.core.connection.MqttFailure
import com.optimeas.opticloudsensor.core.connection.MqttSession
import java.security.cert.CertPathValidatorException
import java.security.cert.CertificateException
import java.util.concurrent.CompletableFuture
import javax.net.ssl.SSLHandshakeException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.future.await

/**
 * Opens MQTT connections with the HiveMQ MQTT Client: MQTT 3.1.1 over TLS, verified against the system trust
 * store, with the device token as user name and no password (see `docs/spec/connection.md`).
 *
 * The client closes a connection when no PINGRESP arrives within the keep-alive time; the specification asks for
 * 20 seconds, which the client does not allow to set (see the open points of `docs/spec/connection.md`).
 */
class HiveMqConnector : MqttConnector {
    override suspend fun connect(endpoint: MqttEndpoint, onMessage: (String, String) -> Unit): MqttSession {
        val closed = CompletableDeferred<MqttFailure>()
        val client = Mqtt3Client.builder()
            .identifier(endpoint.clientId)
            .serverHost(endpoint.host)
            .serverPort(endpoint.port)
            .sslWithDefaultConfig()
            .addDisconnectedListener { context -> closed.complete(MqttFailure(MqttFailure.Kind.LOST, context.cause)) }
            .buildAsync()
        client.publishes(MqttGlobalPublishFilter.ALL) { publish ->
            onMessage(publish.topic.toString(), String(publish.payloadAsBytes, Charsets.UTF_8))
        }
        try {
            client.connectWith()
                .cleanSession(true)
                .keepAlive(KEEP_ALIVE_SECONDS)
                .simpleAuth().username(endpoint.token).applySimpleAuth()
                .send()
                .await()
        } catch (e: Throwable) {
            throw connectFailure(e)
        }
        return Session(client, closed)
    }

    private class Session(private val client: Mqtt3AsyncClient, private val closed: CompletableDeferred<MqttFailure>) :
        MqttSession {
        override suspend fun subscribe(filters: List<String>) {
            val subscribe = Mqtt3Subscribe.builder()
                .addSubscriptions(filters.map { Mqtt3Subscription.builder().topicFilter(it).qos(MqttQos.AT_LEAST_ONCE).build() })
                .build()
            val ack = lost { client.subscribe(subscribe) }
            if (ack.returnCodes.any { it == Mqtt3SubAckReturnCode.FAILURE }) throw MqttFailure(MqttFailure.Kind.SUBSCRIPTION_REFUSED)
        }

        override suspend fun publish(topic: String, payload: String) {
            lost {
                client.publishWith().topic(topic).qos(MqttQos.AT_LEAST_ONCE).payload(payload.toByteArray(Charsets.UTF_8)).send()
            }
        }

        override suspend fun awaitClosed() = closed.await()

        override suspend fun disconnect() {
            if (client.state.isConnected) runCatching { client.disconnect().await() }
        }

        private suspend fun <T> lost(call: () -> CompletableFuture<T>): T = try {
            call().await()
        } catch (e: MqttFailure) {
            throw e
        } catch (e: Exception) {
            throw MqttFailure(MqttFailure.Kind.LOST, e)
        }
    }

    private fun connectFailure(e: Throwable): MqttFailure {
        if (e is Mqtt3ConnAckException) {
            val kind = when (e.mqttMessage.returnCode) {
                Mqtt3ConnAckReturnCode.BAD_USER_NAME_OR_PASSWORD -> MqttFailure.Kind.BAD_CREDENTIALS
                Mqtt3ConnAckReturnCode.NOT_AUTHORIZED -> MqttFailure.Kind.NOT_AUTHORIZED
                else -> MqttFailure.Kind.SERVER_UNAVAILABLE
            }
            return MqttFailure(kind, e)
        }
        val certificate = generateSequence(e) { it.cause }.any {
            it is SSLHandshakeException || it is CertificateException || it is CertPathValidatorException
        }
        return MqttFailure(if (certificate) MqttFailure.Kind.CERTIFICATE else MqttFailure.Kind.UNREACHABLE, e)
    }

    private companion object {
        const val KEEP_ALIVE_SECONDS = 60
    }
}
