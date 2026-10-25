package com.optimeas.opticloudsensor.core.api

import java.util.Base64
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/** The claims the app reads from the user's access token, a JWT (see `docs/spec/sign-in.md`, The session). */
@Serializable
data class AccessTokenClaims(
    val tenantId: String? = null,
    val projectId: String? = null,
    val userId: String? = null,
    val authorityDataId: String? = null,
    /** The moment the token expires, in seconds since 1970. */
    val exp: Long? = null,
) {
    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        /** Reads the claims of a JWT without checking its signature; the server checks it. */
        fun parse(jwt: String): AccessTokenClaims {
            val payload = jwt.split('.').getOrNull(1) ?: throw OptiCloudException.UnexpectedAnswer()
            return try {
                json.decodeFromString(serializer(), String(Base64.getUrlDecoder().decode(payload.trimEnd('=')), Charsets.UTF_8))
            } catch (_: Exception) {
                throw OptiCloudException.UnexpectedAnswer()
            }
        }
    }
}
