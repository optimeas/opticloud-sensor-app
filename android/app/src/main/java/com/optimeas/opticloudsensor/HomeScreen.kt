package com.optimeas.opticloudsensor

import android.text.format.Formatter
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.optimeas.opticloudsensor.core.connection.ConnectionReason
import com.optimeas.opticloudsensor.core.connection.ConnectionState
import com.optimeas.opticloudsensor.core.connection.DeviceSettings
import com.optimeas.opticloudsensor.core.connection.QueueStatus
import com.optimeas.opticloudsensor.storage.AppState
import kotlinx.coroutines.delay

/** Everything the home screen shows. */
data class HomeState(
    val app: AppState,
    val connection: ConnectionState,
    val settings: DeviceSettings,
    val queue: QueueStatus,
    val reportedSensors: String,
)

/** What the home screen can do. */
interface HomeActions {
    fun connect()

    fun disconnect()

    fun setTransmitting(on: Boolean)

    fun chooseDevice()

    fun signOut()
}

/** What the phone is set up for, the connection, and transmission (see `docs/spec/connection.md`, States). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(state: HomeState, actions: HomeActions) {
    var askDeviceChange by remember { mutableStateOf(false) }
    Scaffold(topBar = { TopAppBar(title = { Text(stringResource(R.string.app_name)) }) }) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState())) {
            ConnectionRow(state.connection, actions)
            TransmissionRow(state, actions)
            QueueRow(state.queue)
            HorizontalDivider()
            Row(R.string.home_server, state.app.address.text)
            state.app.device?.let { choice ->
                Row(R.string.home_tenant, choice.tenant.name)
                Row(R.string.home_project, choice.project.name)
                Row(R.string.home_device, choice.device.name)
            }
            Row(R.string.home_session, stringResource(if (state.app.signedIn) R.string.home_signed_in else R.string.home_signed_out))
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { if (state.queue.count > 0) askDeviceChange = true else actions.chooseDevice() },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(stringResource(if (state.app.signedIn) R.string.home_choose_device else R.string.home_sign_in))
                }
                if (state.app.signedIn) {
                    OutlinedButton(onClick = actions::signOut, modifier = Modifier.fillMaxWidth()) {
                        Text(stringResource(R.string.home_sign_out))
                    }
                }
                Text(
                    stringResource(R.string.home_not_built),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
    if (askDeviceChange) {
        AlertDialog(
            onDismissRequest = { askDeviceChange = false },
            title = { Text(stringResource(R.string.change_device_title)) },
            text = { Text(stringResource(R.string.change_device_text, state.queue.count.toInt())) },
            confirmButton = {
                TextButton(onClick = {
                    askDeviceChange = false
                    actions.chooseDevice()
                }) { Text(stringResource(R.string.change_device_button)) }
            },
            dismissButton = { TextButton(onClick = { askDeviceChange = false }) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

@Composable
private fun ConnectionRow(connection: ConnectionState, actions: HomeActions) {
    val connectable = connection == ConnectionState.Disconnected || connection is ConnectionState.Refused
    ListItem(
        overlineContent = { Text(stringResource(R.string.home_connection)) },
        headlineContent = { Text(connectionText(connection)) },
        trailingContent = {
            if (connectable) {
                Button(onClick = actions::connect) { Text(stringResource(R.string.home_connect)) }
            } else {
                OutlinedButton(onClick = actions::disconnect) { Text(stringResource(R.string.home_disconnect)) }
            }
        },
    )
}

@Composable
private fun connectionText(connection: ConnectionState): String = when (connection) {
    ConnectionState.Disconnected -> stringResource(R.string.state_disconnected)
    ConnectionState.Connecting -> stringResource(R.string.state_connecting)
    ConnectionState.Connected -> stringResource(R.string.state_connected)
    is ConnectionState.Refused -> stringResource(R.string.state_refused, reasonText(connection.reason))
    is ConnectionState.Waiting -> {
        val retryAt = connection.retryAt
        if (retryAt == null) {
            stringResource(R.string.state_waiting, reasonText(connection.reason))
        } else {
            var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
            LaunchedEffect(retryAt) {
                while (now < retryAt) {
                    delay(1_000)
                    now = System.currentTimeMillis()
                }
            }
            val seconds = ((retryAt - now + 999) / 1_000).coerceAtLeast(0).toInt()
            stringResource(R.string.state_waiting_retry, reasonText(connection.reason), seconds)
        }
    }
}

@Composable
private fun reasonText(reason: ConnectionReason): String = stringResource(
    when (reason) {
        ConnectionReason.NO_NETWORK -> R.string.reason_no_network
        ConnectionReason.SERVER_NOT_REACHABLE -> R.string.reason_server_not_reachable
        ConnectionReason.CERTIFICATE_NOT_TRUSTED -> R.string.reason_certificate_not_trusted
        ConnectionReason.CONNECTION_LOST -> R.string.reason_connection_lost
        ConnectionReason.TOKEN_REFUSED -> R.string.reason_token_refused
        ConnectionReason.BOUND_TO_ANOTHER_PHONE -> R.string.reason_bound_to_another_phone
        ConnectionReason.NOT_BOUND -> R.string.reason_not_bound
    },
)

@Composable
private fun TransmissionRow(state: HomeState, actions: HomeActions) {
    val settings = state.settings
    val detail = stringResource(R.string.home_transmission_detail, settings.sendRate, state.reportedSensors.ifEmpty { "–" })
    val managed = if ("sendRate" in settings.managed || "sensors" in settings.managed) {
        " · " + stringResource(R.string.home_managed)
    } else {
        ""
    }
    ListItem(
        overlineContent = { Text(stringResource(R.string.home_transmission)) },
        headlineContent = { Text(detail + managed) },
        trailingContent = { Switch(checked = settings.transmitting, onCheckedChange = actions::setTransmitting) },
    )
}

@Composable
private fun QueueRow(queue: QueueStatus) {
    val context = LocalContext.current
    ListItem(
        overlineContent = { Text(stringResource(R.string.home_queue)) },
        headlineContent = {
            Text(stringResource(R.string.home_queue_detail, queue.count.toInt(), Formatter.formatShortFileSize(context, queue.bytes)))
        },
        supportingContent = if (queue.discarded.count > 0) {
            { Text(stringResource(R.string.home_discarded, queue.discarded.count.toInt())) }
        } else {
            null
        },
    )
}

@Composable
private fun Row(label: Int, value: String) {
    ListItem(overlineContent = { Text(stringResource(label)) }, headlineContent = { Text(value) })
}
