package com.optimeas.opticloudsensor.core.api

import java.util.Base64
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** A transport that answers from a list of rules and records every request. */
private class FakeTransport : HttpTransport {
    val requests = mutableListOf<HttpRequest>()
    private val rules = mutableListOf<Pair<(HttpRequest) -> Boolean, (HttpRequest) -> HttpResponse>>()

    fun on(method: String, path: String, answer: (HttpRequest) -> HttpResponse) {
        rules += { r: HttpRequest -> r.method == method && r.url.substringAfter("example.com").substringBefore('?') == path } to answer
    }

    override suspend fun send(request: HttpRequest): HttpResponse {
        requests += request
        return rules.lastOrNull { it.first(request) }?.second?.invoke(request) ?: error("no rule for ${request.method} ${request.url}")
    }
}

private fun ok(json: String) = HttpResponse(200, json.toByteArray())

private fun error(status: Int, errorCode: Int) =
    HttpResponse(status, """{"status":$status,"message":"detail","errorCode":$errorCode}""".toByteArray())

/** An unsigned JWT with the given claims. */
private fun jwt(exp: Long, projectId: String = "p1"): String {
    val encoder = Base64.getUrlEncoder().withoutPadding()
    val payload = """{"tenantId":"t1","projectId":"$projectId","userId":"u1","authorityDataId":"a1","exp":$exp}"""
    return encoder.encodeToString("{}".toByteArray()) + "." + encoder.encodeToString(payload.toByteArray()) + ".sig"
}

private fun HttpRequest.json(): JsonObject = Json.parseToJsonElement(body!!.toString(Charsets.UTF_8)).jsonObject

class OptiCloudClientTest {
    private val address = ServerAddress.parse("https://example.com")!!
    private val now = 1_760_000_000_000L
    private val fresh = TokenPair(jwt(exp = now / 1000 + 3600), "refresh-1")

    @Test
    fun rolesAndLoginWithoutCode() = runTest {
        val transport = FakeTransport()
        transport.on("POST", "/api/noauth/authorization") {
            ok("""[{"authorityId":{"id":"r1"},"authority":"TENANT_USER","tenant":{"id":{"entityType":"TENANT","id":"t1"},"name":"Example"},"enabled":true,"projectCount":3,"extra":1}]""")
        }
        transport.on("POST", "/api/auth/login") { ok("""{"token":"${fresh.token}","refreshToken":"refresh-1","twoFactorRequired":false}""") }
        val changes = mutableListOf<TokenPair?>()
        val client = OptiCloudClient(address, transport = transport, nowMillis = { now }, onTokensChanged = { changes += it })

        val roles = client.roles("user@example.com", "secret")
        assertEquals(listOf(Role("r1", "TENANT_USER", Role.Tenant("t1", "Example"), true, 3)), roles)
        assertEquals("secret", transport.requests[0].json().getValue("password").jsonPrimitive.content)

        val result = client.login("user@example.com", "secret", "r1")
        assertEquals(LoginResult.SignedIn(fresh), result)
        assertEquals("r1", transport.requests[1].json().getValue("authorityId").jsonPrimitive.content)
        assertEquals(listOf<TokenPair?>(fresh), changes)
        assertEquals("p1", client.claims?.projectId)
    }

    @Test
    fun loginWithCode() = runTest {
        val transport = FakeTransport()
        transport.on("POST", "/api/auth/login") { ok("""{"twoFactorRequired":true,"twoFactorToken":"2fa","twoFactorEmail":"u***@example.com"}""") }
        transport.on("POST", "/api/noauth/2fa/verify") { ok("""{"token":"${fresh.token}","refreshToken":"refresh-1"}""") }
        val client = OptiCloudClient(address, transport = transport, nowMillis = { now })

        assertEquals(LoginResult.CodeRequired("2fa", "u***@example.com"), client.login("u", "p", "r1"))
        assertNull(client.tokens)
        client.verify("2fa", "123456")
        assertEquals(fresh, client.tokens)
        assertEquals(JsonObject(mapOf("twoFactorToken" to JsonPrimitive("2fa"), "code" to JsonPrimitive("123456"))), transport.requests[1].json())
    }

    @Test
    fun requestsCarryTheAccessToken() = runTest {
        val transport = FakeTransport()
        transport.on("GET", "/api/projects/enabled") {
            ok("""[{"id":{"entityType":"PROJECT","id":"p1"},"name":"Root","children":[{"id":{"id":"p2"},"name":"Child","children":[]}]}]""")
        }
        val client = OptiCloudClient(address, fresh, transport, nowMillis = { now })

        val projects = client.projects()
        assertEquals(listOf("Root" to 0, "Child" to 1), projects.single().flattened().map { (p, depth) -> p.name to depth })
        assertEquals("Bearer ${fresh.token}", transport.requests.single().headers["X-Authorization"])
    }

    @Test
    fun renewsShortlyBeforeExpiry() = runTest {
        val expiring = TokenPair(jwt(exp = now / 1000 + 60), "refresh-0")
        val transport = FakeTransport()
        transport.on("POST", "/api/auth/token") { ok("""{"token":"${fresh.token}","refreshToken":"refresh-1"}""") }
        transport.on("GET", "/api/projects/enabled") { ok("[]") }
        val client = OptiCloudClient(address, expiring, transport, nowMillis = { now })

        client.projects()
        assertEquals(listOf("/api/auth/token", "/api/projects/enabled"), transport.requests.map { it.url.substringAfter("example.com") })
        assertEquals("refresh-0", transport.requests[0].json().getValue("refreshToken").jsonPrimitive.content)
        assertEquals("Bearer ${fresh.token}", transport.requests[1].headers["X-Authorization"])
    }

    @Test
    fun doesNotRenewWellBeforeExpiry() = runTest {
        val transport = FakeTransport()
        transport.on("GET", "/api/projects/enabled") { ok("[]") }
        OptiCloudClient(address, TokenPair(jwt(exp = now / 1000 + 180), "r"), transport, nowMillis = { now }).projects()
        assertEquals(1, transport.requests.size)
    }

    @Test
    fun expiredTokenIsRenewedAndTheRequestRepeatedOnce() = runTest {
        val transport = FakeTransport()
        var calls = 0
        transport.on("GET", "/api/projects/enabled") { if (calls++ == 0) error(401, 11) else ok("[]") }
        transport.on("POST", "/api/auth/token") { ok("""{"token":"${fresh.token}","refreshToken":"refresh-2"}""") }
        val client = OptiCloudClient(address, fresh, transport, nowMillis = { now })

        client.projects()
        assertEquals(3, transport.requests.size)
        assertEquals("refresh-2", client.tokens?.refreshToken)

        calls = 0
        transport.on("GET", "/api/projects/enabled") { error(401, 11) }
        val e = assertFailsWith<OptiCloudException.Api> { client.projects() }
        assertEquals(11, e.errorCode)
    }

    @Test
    fun errorBodyGivesTheErrorCode() = runTest {
        val transport = FakeTransport()
        transport.on("POST", "/api/devices") { error(400, 31) }
        val client = OptiCloudClient(address, fresh, transport, nowMillis = { now })

        val e = assertFailsWith<OptiCloudException.Api> { client.createDevice("Phone") }
        assertEquals(31, e.errorCode)
        assertEquals("detail", e.serverMessage)
        assertEquals(JsonObject(mapOf("name" to JsonPrimitive("Phone"), "type" to JsonPrimitive(DEVICE_TYPE))), transport.requests.single().json())
    }

    @Test
    fun errorBodyWithStatusAsName() = runTest {
        // As POST /api/auth/login answers a wrong password on the test server.
        val transport = FakeTransport()
        transport.on("POST", "/api/auth/login") {
            HttpResponse(401, """{"status":"UNAUTHORIZED","message":"Authentication failed","errorCode":10,"timestamp":1792938638669,"details":null}""".toByteArray())
        }
        val e = assertFailsWith<OptiCloudException.Api> { OptiCloudClient(address, transport = transport).login("u", "p", "r") }
        assertEquals(401, e.status)
        assertEquals(10, e.errorCode)
        assertEquals("Authentication failed", e.serverMessage)
        assertEquals("/api/auth/login", e.path)
    }

    @Test
    fun unknownUserIsSignInFailed() = runTest {
        // As POST /api/noauth/authorization answers an unknown e-mail address on the test server.
        val transport = FakeTransport()
        transport.on("POST", "/api/noauth/authorization") {
            HttpResponse(400, """{"timestamp":"2026-10-25T14:30:38.586+00:00","status":400,"error":"Bad Request","path":"/api/noauth/authorization"}""".toByteArray())
        }
        val e = assertFailsWith<OptiCloudException.Api> { OptiCloudClient(address, transport = transport).roles("nobody@example.com", "p") }
        assertEquals(OptiCloudException.Code.SIGN_IN_FAILED, e.errorCode)
    }

    @Test
    fun errorWithoutBody() = runTest {
        val transport = FakeTransport()
        transport.on("GET", "/api/projects/enabled") { HttpResponse(502, ByteArray(0)) }
        val e = assertFailsWith<OptiCloudException.Api> { OptiCloudClient(address, fresh, transport, nowMillis = { now }).projects() }
        assertEquals(502, e.status)
        assertNull(e.errorCode)
    }

    @Test
    fun notSignedIn() = runTest {
        assertFailsWith<OptiCloudException.NotSignedIn> { OptiCloudClient(address, transport = FakeTransport()).projects() }
    }

    @Test
    fun devicesAreReadPageByPage() = runTest {
        val transport = FakeTransport()
        transport.on("GET", "/api/tenants/t1/devices") { request ->
            if ("page=0" in request.url) {
                ok("""{"data":[{"id":{"entityType":"DEVICE","id":"d1"},"name":"Pump","type":"default"}],"hasNext":true}""")
            } else {
                ok("""{"data":[{"id":{"entityType":"DEVICE","id":"d2"},"name":"Anna's phone","type":"$DEVICE_TYPE","label":null}],"hasNext":false}""")
            }
        }
        val client = OptiCloudClient(address, fresh, transport, nowMillis = { now })

        val devices = client.devices("t1", "p1", textSearch = "an na")
        assertEquals(listOf("d1", "d2"), devices.map { it.id })
        assertEquals(listOf(false, true), devices.map { it.isSensorAppDevice })
        assertEquals(
            "https://example.com/api/tenants/t1/devices?projectId=p1&limit=100&page=1&textSearch=an%20na",
            transport.requests[1].url,
        )
    }

    @Test
    fun credentialsAndBinding() = runTest {
        val transport = FakeTransport()
        transport.on("GET", "/api/device/d1/credentials") { ok("""{"credentialsType":"ACCESS_TOKEN","credentialsId":"tok","enabled":true}""") }
        transport.on("GET", "/api/plugins/telemetry/DEVICE/d1/values/attributes/SHARED_SCOPE") {
            ok("""[{"key":"sendRate","value":5,"lastUpdateTs":1},{"key":"sensorAppInstallation","value":"abc","lastUpdateTs":2}]""")
        }
        transport.on("POST", "/api/plugins/telemetry/DEVICE/d1/attributes/SHARED_SCOPE") { HttpResponse(200, ByteArray(0)) }
        val client = OptiCloudClient(address, fresh, transport, nowMillis = { now })

        assertEquals(DeviceCredentials("ACCESS_TOKEN", "tok", true), client.credentials("d1"))
        val attributes = client.sharedAttributes("d1")
        assertEquals(Binding.THIS_PHONE, Binding.of(attributes, "abc"))
        assertEquals(Binding.OTHER_PHONE, Binding.of(attributes, "xyz"))
        assertEquals(Binding.NONE, Binding.of(attributes.take(1), "abc"))

        client.setSharedAttributes("d1", JsonObject(mapOf(BINDING_ATTRIBUTE to JsonPrimitive("abc"))))
        assertEquals("abc", transport.requests.last().json().getValue(BINDING_ATTRIBUTE).jsonPrimitive.content)
    }

    @Test
    fun unexpectedAnswer() = runTest {
        val transport = FakeTransport()
        transport.on("POST", "/api/auth/login") { ok("""{"twoFactorRequired":false}""") }
        assertIs<OptiCloudException.UnexpectedAnswer>(
            runCatching { OptiCloudClient(address, transport = transport).login("u", "p", "r") }.exceptionOrNull(),
        )
    }

    @Test
    fun signOutForgetsTheTokens() {
        val changes = mutableListOf<TokenPair?>()
        val client = OptiCloudClient(address, fresh, FakeTransport(), onTokensChanged = { changes += it })
        client.signOut()
        assertTrue(!client.isSignedIn)
        assertEquals(listOf<TokenPair?>(null), changes)
    }
}

class ServerAddressTest {
    @Test
    fun acceptsHttpsWithHost() {
        assertEquals("https://cloud.example.com", ServerAddress.parse("  https://Cloud.Example.com/home?x=1 ")?.text)
        assertEquals("https://cloud.example.com:8443", ServerAddress.parse("https://cloud.example.com:8443/")?.text)
        assertEquals("cloud.example.com", ServerAddress.parse("https://cloud.example.com")?.mqttHost)
    }

    @Test
    fun refusesOtherAddresses() {
        assertNull(ServerAddress.parse("http://cloud.example.com"))
        assertNull(ServerAddress.parse("cloud.example.com"))
        assertNull(ServerAddress.parse("https://"))
        assertNull(ServerAddress.parse("https://exa mple.com"))
    }
}

class AccessTokenClaimsTest {
    @Test
    fun readsTheClaims() {
        val claims = AccessTokenClaims.parse(jwt(exp = 1_760_003_600, projectId = "p9"))
        assertEquals(AccessTokenClaims("t1", "p9", "u1", "a1", 1_760_003_600), claims)
    }

    @Test
    fun refusesSomethingElse() {
        assertFailsWith<OptiCloudException.UnexpectedAnswer> { AccessTokenClaims.parse("not a token") }
    }
}
