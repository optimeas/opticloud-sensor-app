package com.optimeas.opticloudsensor

import android.app.Application
import com.optimeas.opticloudsensor.storage.AppModel

class SensorApplication : Application() {
    val appModel: AppModel by lazy { AppModel(this) }
}
