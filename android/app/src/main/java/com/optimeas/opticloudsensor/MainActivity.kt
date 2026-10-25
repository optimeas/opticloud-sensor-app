package com.optimeas.opticloudsensor

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.optimeas.opticloudsensor.signin.SignInFlow
import com.optimeas.opticloudsensor.signin.SignInViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = (application as SensorApplication).appModel
        setContent {
            val context = LocalContext.current
            val colorScheme =
                if (isSystemInDarkTheme()) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
            MaterialTheme(colorScheme = colorScheme) {
                val signIn: SignInViewModel = viewModel(factory = viewModelFactory { initializer { SignInViewModel(app) } })
                val appState by app.state.collectAsStateWithLifecycle()
                val signInState by signIn.state.collectAsStateWithLifecycle()
                if (signInState.active || appState.device == null) {
                    SignInFlow(signInState, appState.address.text, signIn, canLeave = appState.device != null)
                } else {
                    HomeScreen(appState, onChooseDevice = signIn::start, onSignOut = app::signOut)
                }
            }
        }
    }
}
