/*
 * Generador de Par de Claves ECC en ESP32-S3 con Medición de Rendimiento
 * -----------------------------------------------------------------------
 * Este código genera un par de claves ECC y mide el tiempo total que toma
 * la operación, aprovechando la aceleración de hardware del chip.
 */

#include "mbedtls/pk.h"
#include "mbedtls/entropy.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/error.h"

// Variables para medir el tiempo de ejecución
unsigned long startTime = 0;
unsigned long duration = 0;

// Función para imprimir errores de mbedtls de forma legible
void print_mbedtls_error(const char* func_name, int ret_code) {
  char error_buf[128];
  mbedtls_strerror(ret_code, error_buf, sizeof(error_buf));
  Serial.printf("Error en '%s'. Código: -0x%04X - %s\n", func_name, (unsigned int)-ret_code, error_buf);
}

void setup() {
  Serial.begin(115200);
  while (!Serial) {
    delay(10); 
  }
  Serial.println("\n=======================================================");
  Serial.println("  Generador de Claves ECC con Medición de Tiempo");
  Serial.println("=======================================================");

  // --- INICIAMOS LA MEDICIÓN DE TIEMPO ---
  startTime = micros();

  int ret = 1; 

  mbedtls_pk_context key_pair;
  mbedtls_entropy_context entropy;
  mbedtls_ctr_drbg_context ctr_drbg;
  
  mbedtls_pk_init(&key_pair);
  mbedtls_ctr_drbg_init(&ctr_drbg);
  mbedtls_entropy_init(&entropy);
  
  const char *personalization = "esp32-s3-ecc-key-gen-v1";

  Serial.println("1. Sembrando el generador de números aleatorios (TRNG)...");
  ret = mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_entropy_func, &entropy,
                              (const unsigned char *)personalization,
                              strlen(personalization));
  if (ret != 0) {
    print_mbedtls_error("mbedtls_ctr_drbg_seed", ret);
    goto cleanup; 
  }

  Serial.println("\n2. Preparando contexto para la clave ECC...");
  ret = mbedtls_pk_setup(&key_pair, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY));
  if (ret != 0) {
    print_mbedtls_error("mbedtls_pk_setup", ret);
    goto cleanup;
  }
  
  Serial.println("3. Generando el par de claves (curva SECP256R1)...");
  ret = mbedtls_ecp_gen_key(MBEDTLS_ECP_DP_SECP256R1, mbedtls_pk_ec(key_pair),
                            mbedtls_ctr_drbg_random, &ctr_drbg);
  if (ret != 0) {
    print_mbedtls_error("mbedtls_ecp_gen_key", ret);
    goto cleanup;
  }
  Serial.println("   ...Par de claves generado con éxito!");

  Serial.println("\n4. Exportando claves a formato PEM...");
  
  unsigned char pub_key_pem[512];
  unsigned char priv_key_pem[512];
  
  ret = mbedtls_pk_write_pubkey_pem(&key_pair, pub_key_pem, sizeof(pub_key_pem));
  if (ret != 0) {
    print_mbedtls_error("mbedtls_pk_write_pubkey_pem", ret);
    goto cleanup;
  }
  
  ret = mbedtls_pk_write_key_pem(&key_pair, priv_key_pem, sizeof(priv_key_pem));
  if (ret != 0) {
    print_mbedtls_error("mbedtls_pk_write_key_pem", ret);
    goto cleanup;
  }

  // --- FINALIZAMOS LA MEDICIÓN DE TIEMPO ---
  duration = micros() - startTime;

  // Ahora imprimimos los resultados
  Serial.println("\n-------------------- RESULTADO DEL RENDIMIENTO --------------------");
  Serial.print("La generación completa del par de claves tomó: ");
  Serial.print(duration);
  Serial.print(" microsegundos (");
  Serial.print(duration / 1000.0, 3); // Imprime con 3 decimales para ver milisegundos
  Serial.println(" milisegundos)");
  Serial.println("-----------------------------------------------------------------");

  Serial.println("\n-------------------- CLAVE PÚBLICA (PEM) --------------------");
  Serial.println((char*)pub_key_pem);
  
  Serial.println("\n-------------------- CLAVE PRIVADA (PEM) --------------------");
  Serial.println((char*)priv_key_pem);

  Serial.println("=======================================================");
  Serial.println("Proceso completado.");

cleanup:
  mbedtls_pk_free(&key_pair);
  mbedtls_ctr_drbg_free(&ctr_drbg);
  mbedtls_entropy_free(&entropy);
}

void loop() {
  delay(10000);
}