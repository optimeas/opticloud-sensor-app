package com.optimeas.opticloudsensor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.optimeas.opticloudsensor.storage.AppState

/** What the phone is set up for. Connecting and transmitting follow in a later step. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(state: AppState, onChooseDevice: () -> Unit, onSignOut: () -> Unit) {
    Scaffold(topBar = { TopAppBar(title = { Text(stringResource(R.string.app_name)) }) }) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState())) {
            Row(R.string.home_server, state.address.text)
            state.device?.let { choice ->
                Row(R.string.home_tenant, choice.tenant.name)
                Row(R.string.home_project, choice.project.name)
                Row(R.string.home_device, choice.device.name)
            }
            Row(R.string.home_session, stringResource(if (state.signedIn) R.string.home_signed_in else R.string.home_signed_out))
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = onChooseDevice, modifier = Modifier.fillMaxWidth()) {
                    Text(stringResource(if (state.signedIn) R.string.home_choose_device else R.string.home_sign_in))
                }
                if (state.signedIn) {
                    OutlinedButton(onClick = onSignOut, modifier = Modifier.fillMaxWidth()) {
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
}

@Composable
private fun Row(label: Int, value: String) {
    ListItem(overlineContent = { Text(stringResource(label)) }, headlineContent = { Text(value) })
}
