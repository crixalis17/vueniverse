package com.whypulse.why_pulse.platform

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.KeyStore
import java.security.SecureRandom
import java.util.Properties
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class PlatformSecurityApiImpl(private val context: Context) : PlatformSecurityApi {
  private val keyStore: KeyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
  private val keyRecordsFile: File
    get() = File(context.noBackupFilesDir, KEY_RECORDS_FILE)

  @Synchronized
  override fun openStore(kind: SecureStoreKind): SecureStoreMaterial {
    val database = databaseFile(kind)
    val properties = readKeyRecords()
    val recordKey = recordKey(kind)
    val wrapped = properties.getProperty(recordKey)

    if (wrapped == null && database.exists()) {
      throw FlutterError(
        "STORE_KEY_MISSING",
        "The ${kind.name.lowercase()} database exists but its wrapped key is missing.",
        kind.name.lowercase(),
      )
    }

    val databaseIsNew = !database.exists()
    val passphrase = if (wrapped == null) {
      createAndPersistPassphrase(kind, properties)
    } else {
      unwrapPassphrase(kind, wrapped)
    }

    return SecureStoreMaterial(
      databasePath = database.absolutePath,
      passphrase = passphrase,
      created = databaseIsNew,
    )
  }

  @Synchronized
  override fun deleteStore(kind: SecureStoreKind) {
    val database = databaseFile(kind)
    listOf("", "-wal", "-shm", "-journal").forEach { suffix ->
      val candidate = File(database.absolutePath + suffix)
      if (candidate.exists() && !candidate.delete()) {
        throw FlutterError(
          "STORE_DELETE_FAILED",
          "Could not delete an encrypted ${kind.name.lowercase()} store file.",
          candidate.name,
        )
      }
    }

    val properties = readKeyRecords()
    properties.remove(recordKey(kind))
    writeKeyRecords(properties)
    if (keyStore.containsAlias(alias(kind))) {
      keyStore.deleteEntry(alias(kind))
    }
  }

  private fun databaseFile(kind: SecureStoreKind): File {
    context.noBackupFilesDir.mkdirs()
    val name = when (kind) {
      SecureStoreKind.LIVE -> "whypulse_live.db"
      SecureStoreKind.DEMO -> "whypulse_demo.db"
    }
    return File(context.noBackupFilesDir, name)
  }

  private fun createAndPersistPassphrase(
    kind: SecureStoreKind,
    properties: Properties,
  ): String {
    val raw = ByteArray(32).also { SecureRandom().nextBytes(it) }
    return try {
      val key = getOrCreateWrappingKey(kind)
      val cipher = Cipher.getInstance(TRANSFORMATION)
      cipher.init(Cipher.ENCRYPT_MODE, key)
      val encrypted = cipher.doFinal(raw)
      val record = listOf(cipher.iv, encrypted).joinToString(":") {
        Base64.encodeToString(it, Base64.NO_WRAP)
      }
      properties.setProperty(recordKey(kind), record)
      writeKeyRecords(properties)
      Base64.encodeToString(raw, Base64.NO_WRAP)
    } catch (error: Exception) {
      if (keyStore.containsAlias(alias(kind))) {
        keyStore.deleteEntry(alias(kind))
      }
      throw FlutterError(
        "STORE_KEY_CREATE_FAILED",
        "Could not create the encrypted ${kind.name.lowercase()} store key.",
        error.javaClass.simpleName,
      )
    } finally {
      raw.fill(0)
    }
  }

  private fun unwrapPassphrase(kind: SecureStoreKind, wrapped: String): String {
    try {
      val parts = wrapped.split(":")
      if (parts.size != 2 || !keyStore.containsAlias(alias(kind))) {
        throw IllegalStateException("Wrapped key or Android Keystore alias is unavailable")
      }
      val iv = Base64.decode(parts[0], Base64.NO_WRAP)
      val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)
      val key = keyStore.getKey(alias(kind), null) as SecretKey
      val cipher = Cipher.getInstance(TRANSFORMATION)
      cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
      val raw = cipher.doFinal(encrypted)
      return try {
        Base64.encodeToString(raw, Base64.NO_WRAP)
      } finally {
        raw.fill(0)
      }
    } catch (error: Exception) {
      throw FlutterError(
        "STORE_KEY_UNAVAILABLE",
        "The encrypted ${kind.name.lowercase()} store key could not be recovered.",
        error.javaClass.simpleName,
      )
    }
  }

  private fun getOrCreateWrappingKey(kind: SecureStoreKind): SecretKey {
    if (keyStore.containsAlias(alias(kind))) {
      return keyStore.getKey(alias(kind), null) as SecretKey
    }
    val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER)
    val spec = KeyGenParameterSpec.Builder(
      alias(kind),
      KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
    )
      .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
      .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
      .setKeySize(256)
      .setRandomizedEncryptionRequired(true)
      .build()
    generator.init(spec)
    return generator.generateKey()
  }

  private fun readKeyRecords(): Properties {
    val properties = Properties()
    if (!keyRecordsFile.exists()) return properties
    try {
      FileInputStream(keyRecordsFile).use(properties::load)
      return properties
    } catch (error: Exception) {
      throw FlutterError(
        "STORE_KEY_RECORDS_UNREADABLE",
        "The no-backup key record could not be read.",
        error.javaClass.simpleName,
      )
    }
  }

  private fun writeKeyRecords(properties: Properties) {
    context.noBackupFilesDir.mkdirs()
    val temporary = File(context.noBackupFilesDir, "$KEY_RECORDS_FILE.tmp")
    try {
      FileOutputStream(temporary).use { output ->
        properties.store(output, null)
        output.fd.sync()
      }
      if (keyRecordsFile.exists() && !keyRecordsFile.delete()) {
        throw IllegalStateException("Could not replace key record")
      }
      if (!temporary.renameTo(keyRecordsFile)) {
        throw IllegalStateException("Could not commit key record")
      }
    } catch (error: Exception) {
      temporary.delete()
      throw FlutterError(
        "STORE_KEY_RECORDS_WRITE_FAILED",
        "The no-backup key record could not be written.",
        error.javaClass.simpleName,
      )
    }
  }

  private fun alias(kind: SecureStoreKind): String = when (kind) {
    SecureStoreKind.LIVE -> "whypulse_live_db_wrap_v1"
    SecureStoreKind.DEMO -> "whypulse_demo_db_wrap_v1"
  }

  private fun recordKey(kind: SecureStoreKind): String = "${kind.name.lowercase()}.wrapped.v1"

  private companion object {
    const val KEYSTORE_PROVIDER = "AndroidKeyStore"
    const val TRANSFORMATION = "AES/GCM/NoPadding"
    const val KEY_RECORDS_FILE = "whypulse_store_keys.properties"
  }
}
