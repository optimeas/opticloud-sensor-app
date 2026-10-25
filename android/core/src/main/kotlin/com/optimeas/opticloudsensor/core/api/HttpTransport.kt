package com.optimeas.opticloudsensor.core.api

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class HttpRequest(val method: String, val url: String, val headers: Map<String, String>, val body: ByteArray? = null)

data class HttpResponse(val status: Int, val body: ByteArray)

/** Sends HTTP requests. [UrlConnectionTransport] is the transport of the app; tests replace it. */
fun interface HttpTransport {
    /** Throws an [IOException] when the server cannot be reached. */
    suspend fun send(request: HttpRequest): HttpResponse
}

/** Sends requests with the platform's [HttpURLConnection], which checks certificates against the system trust store. */
class UrlConnectionTransport(private val timeoutMillis: Int = 30_000) : HttpTransport {
    override suspend fun send(request: HttpRequest): HttpResponse = withContext(Dispatchers.IO) {
        val connection = URI(request.url).toURL().openConnection() as HttpURLConnection
        try {
            connection.requestMethod = request.method
            connection.connectTimeout = timeoutMillis
            connection.readTimeout = timeoutMillis
            connection.useCaches = false
            request.headers.forEach { (name, value) -> connection.setRequestProperty(name, value) }
            if (request.body != null) {
                connection.doOutput = true
                connection.outputStream.use { it.write(request.body) }
            }
            val status = connection.responseCode
            val stream = if (status >= 400) connection.errorStream else connection.inputStream
            HttpResponse(status, stream?.use { it.readBytes() } ?: ByteArray(0))
        } finally {
            connection.disconnect()
        }
    }
}
