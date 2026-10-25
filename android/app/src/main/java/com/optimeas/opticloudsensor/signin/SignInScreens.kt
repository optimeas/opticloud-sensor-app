package com.optimeas.opticloudsensor.signin

import android.os.Build
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.optimeas.opticloudsensor.R
import com.optimeas.opticloudsensor.core.api.Binding

/** The flow of sign-in and device selection. [address] prefills the address field. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInFlow(state: SignInState, address: String, model: SignInViewModel, canLeave: Boolean) {
    val step = state.step
    val canGoBack = step !is Step.Credentials || canLeave
    BackHandler(enabled = canGoBack && !state.busy) { model.back() }
    val title = when (step) {
        Step.Credentials -> R.string.sign_in_title
        is Step.Tenants -> R.string.tenant_title
        is Step.Code -> R.string.code_title
        is Step.Projects -> R.string.project_title
        is Step.Devices -> R.string.devices_title
    }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(title)) },
                navigationIcon = {
                    if (canGoBack) {
                        IconButton(onClick = model::back, enabled = !state.busy) {
                            Icon(BackArrow, contentDescription = stringResource(R.string.back))
                        }
                    }
                },
            )
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).imePadding()) {
            if (state.busy) LinearProgressIndicator(Modifier.fillMaxWidth()) else Spacer(Modifier.padding(top = 4.dp))
            state.message?.let { Message(it) }
            when (step) {
                Step.Credentials -> CredentialsStep(address, state.busy, model)
                is Step.Tenants -> TenantStep(step, state.busy, model)
                is Step.Code -> CodeStep(step, state.busy, model)
                is Step.Projects -> ProjectStep(step, state.busy, model)
                is Step.Devices -> DeviceStep(step, state.busy, model)
            }
        }
    }
    state.takeOverCandidate?.let { row ->
        AlertDialog(
            onDismissRequest = model::cancelTakeOver,
            title = { Text(stringResource(R.string.take_over_title)) },
            text = { Text(stringResource(R.string.take_over_text, row.device.name)) },
            confirmButton = {
                TextButton(onClick = { model.choose(row, takeOver = true) }) {
                    Text(stringResource(R.string.take_over_button), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = model::cancelTakeOver) { Text(stringResource(R.string.cancel)) } },
        )
    }
}

@Composable
private fun Message(message: UserMessage) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
        Text(stringResource(message.text), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
        message.detail?.let {
            Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun CredentialsStep(initialAddress: String, busy: Boolean, model: SignInViewModel) {
    var address by rememberSaveable { mutableStateOf(initialAddress) }
    var email by rememberSaveable { mutableStateOf("") }
    // The password is not saved across process death.
    var password by androidx.compose.runtime.remember { mutableStateOf("") }
    val canSubmit = !busy && address.isNotBlank() && email.isNotBlank() && password.isNotEmpty()
    val submit = { if (canSubmit) model.signIn(address, email, password) }
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text(stringResource(R.string.sign_in_address)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, imeAction = ImeAction.Next, autoCorrectEnabled = false),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text(stringResource(R.string.sign_in_email)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next, autoCorrectEnabled = false),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text(stringResource(R.string.sign_in_password)) },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = ImeAction.Go),
            keyboardActions = KeyboardActions(onGo = { submit() }),
            modifier = Modifier.fillMaxWidth(),
        )
        Button(onClick = submit, enabled = canSubmit, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.sign_in_button))
        }
    }
}

@Composable
private fun TenantStep(step: Step.Tenants, busy: Boolean, model: SignInViewModel) {
    LazyColumn {
        items(step.roles, key = { it.authorityId }) { role ->
            ListItem(
                headlineContent = { Text(role.tenant.name) },
                supportingContent = role.authority?.let { { Text(it) } },
                modifier = Modifier.clickable(enabled = !busy) { model.chooseTenant(role) },
            )
            HorizontalDivider()
        }
    }
}

@Composable
private fun CodeStep(step: Step.Code, busy: Boolean, model: SignInViewModel) {
    var code by rememberSaveable { mutableStateOf("") }
    val submit = { if (!busy && code.isNotBlank()) model.submitCode(code) }
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(stringResource(R.string.code_sent, step.email))
        OutlinedTextField(
            value = code,
            onValueChange = { code = it },
            label = { Text(stringResource(R.string.code_field)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { submit() }),
            modifier = Modifier.fillMaxWidth(),
        )
        Button(onClick = submit, enabled = !busy && code.isNotBlank(), modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.code_confirm))
        }
        TextButton(onClick = model::resendCode, enabled = !busy) { Text(stringResource(R.string.code_resend)) }
    }
}

@Composable
private fun ProjectStep(step: Step.Projects, busy: Boolean, model: SignInViewModel) {
    LazyColumn {
        items(step.projects, key = { it.first.id }) { (project, depth) ->
            ListItem(
                headlineContent = { Text(project.name) },
                supportingContent = if (project.id == step.current) {
                    { Text(stringResource(R.string.project_current)) }
                } else {
                    null
                },
                modifier = Modifier
                    .clickable(enabled = !busy) { model.chooseProject(project) }
                    .padding(start = (depth * 24).dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DeviceStep(step: Step.Devices, busy: Boolean, model: SignInViewModel) {
    val context = LocalContext.current
    var search by rememberSaveable { mutableStateOf(step.search) }
    var name by rememberSaveable {
        // The name of the phone as the user set it in the system settings, else the model.
        mutableStateOf(Settings.Global.getString(context.contentResolver, Settings.Global.DEVICE_NAME) ?: Build.MODEL)
    }
    PullToRefreshBox(isRefreshing = busy, onRefresh = model::refreshDevices) {
        LazyColumn(Modifier.fillMaxSize()) {
            item {
                OutlinedTextField(
                    value = search,
                    onValueChange = { search = it },
                    label = { Text(stringResource(R.string.devices_search)) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { model.search(search) }),
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                )
            }
            if (step.rows.isEmpty()) {
                item {
                    Text(
                        stringResource(R.string.devices_empty),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
            }
            items(step.rows, key = { it.device.id }) { row ->
                val other = row.binding == Binding.OTHER_PHONE
                ListItem(
                    headlineContent = {
                        Text(row.device.name, color = if (other) MaterialTheme.colorScheme.onSurfaceVariant else Color.Unspecified)
                    },
                    supportingContent = {
                        Text(
                            stringResource(
                                when (row.binding) {
                                    Binding.THIS_PHONE -> R.string.binding_this_phone
                                    Binding.OTHER_PHONE -> R.string.binding_other_phone
                                    Binding.NONE -> R.string.binding_none
                                },
                            ),
                        )
                    },
                    modifier = Modifier.clickable(enabled = !busy) { model.choose(row) },
                )
                HorizontalDivider()
            }
            item {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.devices_new), style = MaterialTheme.typography.titleMedium)
                    Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            label = { Text(stringResource(R.string.devices_new_name)) },
                            singleLine = true,
                            modifier = Modifier.weight(1f),
                        )
                        Spacer(Modifier.width(8.dp))
                        Button(onClick = { model.createDevice(name) }, enabled = !busy && name.isNotBlank()) {
                            Text(stringResource(R.string.devices_create))
                        }
                    }
                }
            }
        }
    }
}

/** An arrow pointing left, for the back button. */
private val BackArrow: ImageVector = ImageVector.Builder("BackArrow", 24.dp, 24.dp, 24f, 24f).path(
    fill = SolidColor(Color.Black),
) {
    moveTo(20f, 11f)
    horizontalLineTo(7.8f)
    lineTo(13.4f, 5.4f)
    lineTo(12f, 4f)
    lineTo(4f, 12f)
    lineTo(12f, 20f)
    lineTo(13.4f, 18.6f)
    lineTo(7.8f, 13f)
    horizontalLineTo(20f)
    close()
}.build()
