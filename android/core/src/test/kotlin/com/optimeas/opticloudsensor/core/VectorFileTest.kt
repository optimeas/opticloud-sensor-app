package com.optimeas.opticloudsensor.core

import kotlin.test.Test
import kotlin.test.assertEquals

class VectorFileTest {
    /** A new vector file needs a test here; otherwise its cases would silently not run. */
    @Test
    fun everyVectorFileIsCovered() {
        val files = Vectors.directory.listFiles { file -> file.extension == "json" }!!.map { it.name }.toSet()
        assertEquals(files, Vectors.covered)
    }
}
