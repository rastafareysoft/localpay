// Incluir las cabeceras necesarias de mbedTLS
// NOTA: No incluimos mbedtls/ecdh.h ya que no está habilitado por defecto
#include "mbedtls/ecdsa.h"
#include "mbedtls/ecp.h"
#include "mbedtls/sha256.h"
#include "mbedtls/entropy.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/pk.h"      // Para parsear claves PEM
#include "mbedtls/error.h" // Para decodificar errores

// --- Configuración del Benchmark ---
#define CURVE_ID MBEDTLS_ECP_DP_SECP256R1

// Función de ayuda para imprimir errores de mbedTLS
void print_mbedtls_error(const char* func_name, int ret_code) {
  if (ret_code != 0) {
    char error_buf[100];
    mbedtls_strerror(ret_code, error_buf, 100);
    Serial.printf("Error en %s: -0x%04X - %s\n", func_name, (unsigned int)-ret_code, error_buf);
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000); // Dar tiempo para abrir el Monitor Serie
  Serial.println("==========================================");
  Serial.println("   Benchmark Criptografía ECC (secp256r1)   ");
  Serial.println("           en ESP32-S3                      ");
  Serial.println("==========================================");

  // --- Inicialización del Generador de Números Aleatorios (RNG) ---
  mbedtls_entropy_context entropy;
  mbedtls_ctr_drbg_context ctr_drbg;
  const char *pers = "ecc-benchmark-esp32";

  mbedtls_entropy_init(&entropy);
  mbedtls_ctr_drbg_init(&ctr_drbg);
  int ret = mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_entropy_func, &entropy,
                                  (const unsigned char *)pers, strlen(pers));
  if (ret != 0) {
    print_mbedtls_error("mbedtls_ctr_drbg_seed", ret);
    return;
  }
  Serial.println("OK: Generador de números aleatorios inicializado.");
  Serial.println();

  // Variables para medir el tiempo
  unsigned long startTime, elapsedTime;

  // --- 1. Benchmark: Generación de Clave ---
  mbedtls_pk_context key_pair_ctx;
  mbedtls_pk_init(&key_pair_ctx);

  startTime = micros();
  // Usamos el contexto PK para generar, es más genérico
  ret = mbedtls_pk_setup(&key_pair_ctx, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY));
  ret = mbedtls_ecp_gen_key(CURVE_ID, mbedtls_pk_ec(key_pair_ctx), mbedtls_ctr_drbg_random, &ctr_drbg);
  elapsedTime = micros() - startTime;
  
  print_mbedtls_error("Generación de Clave", ret);
  if (ret == 0) {
    Serial.printf("-> Benchmark Generación de Clave: %lu microsegundos (~%lu ms)\n", elapsedTime, elapsedTime / 1000);
  }
  Serial.println();


  // --- 2. Benchmark: Firma (ECDSA) ---
  unsigned char msg_hash[32];
  unsigned char signature[MBEDTLS_ECDSA_MAX_LEN];
  size_t sig_len;
  const char *message = "Esta es la transacción que vamos a firmar.";

  mbedtls_sha256((const unsigned char *)message, strlen(message), msg_hash, 0);

  startTime = micros();
  // La función de firma desde el contexto PK es más simple
  ret = mbedtls_pk_sign(&key_pair_ctx, MBEDTLS_MD_SHA256, msg_hash, sizeof(msg_hash), signature, sizeof(signature), &sig_len, mbedtls_ctr_drbg_random, &ctr_drbg);
  elapsedTime = micros() - startTime;

  print_mbedtls_error("Firma (ECDSA)", ret);
  if (ret == 0) {
    Serial.printf("-> Benchmark Firma (ECDSA): %lu microsegundos (~%lu ms)\n", elapsedTime, elapsedTime / 1000);
  }
  Serial.println();


  // --- 3. Benchmark: Verificación (ECDSA) ---
  startTime = micros();
  // La función de verificación desde el contexto PK también es más simple
  ret = mbedtls_pk_verify(&key_pair_ctx, MBEDTLS_MD_SHA256, msg_hash, sizeof(msg_hash), signature, sig_len);
  elapsedTime = micros() - startTime;
  
  print_mbedtls_error("Verificación (ECDSA)", ret);
  if (ret == 0) {
    Serial.printf("-> Benchmark Verificación (ECDSA): %lu microsegundos (~%lu ms)\n", elapsedTime, elapsedTime / 1000);
  }
  Serial.println();
  
  // Liberar memoria
  mbedtls_pk_free(&key_pair_ctx);
  mbedtls_ctr_drbg_free(&ctr_drbg);
  mbedtls_entropy_free(&entropy);
  
  Serial.println("Benchmark finalizado.");
}

void loop() {
  // No hacer nada en el loop
}