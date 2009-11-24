#ifndef HEADER_VMAC_H
#define HEADER_VMAC_H

/* --------------------------------------------------------------------------
 * VMAC and VHASH Implementation by Ted Krovetz (tdk@acm.org) and Wei Dai.
 * This implementation is herby placed in the public domain.
 * The authors offers no warranty. Use at your own risk.
 * Please send bug reports to the authors.
 * Last modified: 17 APR 08, 1700 PDT
 * ----------------------------------------------------------------------- */

/* --------------------------------------------------------------------------
 * User definable settings.
 * ----------------------------------------------------------------------- */
#define VMAC_TAG_LEN   64 /* Must be 64 or 128 - 64 sufficient for most    */
#define VMAC_KEY_LEN  128 /* Must be 128, 192 or 256                       */
#define VMAC_NHBYTES  128 /* Must 2^i for any 3 < i < 13. Standard = 128   */
#define VMAC_PREFER_BIG_ENDIAN  0  /* Prefer non-x86 */

#define VMAC_USE_OPENSSL  0 /* Set to non-zero to use OpenSSL's AES        */
#define VMAC_CACHE_NONCES 1 /* Set to non-zero to cause caching            */
                            /* of consecutive nonces on 64-bit tags        */

#define VMAC_RUN_TESTS 0  /* Set to non-zero to check vectors and speed    */
#define VMAC_HZ (448e6)  /* Set to hz of host machine to get speed        */
#define VMAC_HASH_ONLY 0  /* Set to non-zero to time hash only (not-mac)   */
/* Speeds of cpus I have access to
#define hz (2400e6)  glyme Core 2 "Conroe"
#define hz (2000e6)  jupiter G5
#define hz (1592e6)  titan
#define hz (2793e6)  athena/gaia
#define hz (1250e6)  isis G4
#define hz (2160e6)  imac Core 2 "Merom"
#define hz (266e6)   ppc/arm
#define hz (400e6)   mips
*/

/* --------------------------------------------------------------------------
 * This implementation uses uint32_t and uint64_t as names for unsigned 32-
 * and 64-bit integer types. These are defined in C99 stdint.h. The
 * following may need adaptation if you are not running a C99 or
 * Microsoft C environment.
 * ----------------------------------------------------------------------- */
#define VMAC_USE_STDINT 1  /* Set to zero if system has no stdint.h        */
 
#if VMAC_USE_STDINT && !_MSC_VER /* Try stdint.h if non-Microsoft          */
#ifdef  __cplusplus
#define __STDC_CONSTANT_MACROS
#endif
//#include <stdint.h>
#elif (_MSC_VER)                  /* Microsoft C does not have stdint.h    */
typedef unsigned __int32 uint32_t;
typedef unsigned __int64 uint64_t;
#define UINT64_C(v) v ## UI64
#else                             /* Guess sensibly - may need adaptation  */
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
#define UINT64_C(v) v ## ULL
#endif

/* --------------------------------------------------------------------------
 * This implementation supports two free AES implementations: OpenSSL's and
 * Paulo Barreto's. To use OpenSSL's, you will need to include the OpenSSL
 * crypto library (eg, gcc -lcrypto foo.c). For Barreto's, you will need
 * to compile rijndael-alg-fst.c, last seen at http://www.iaik.tu-graz.ac.at/
 * research/krypto/AES/old/~rijmen/rijndael/rijndael-fst-3.0.zip and
 * http://homes.esat.kuleuven.be/~rijmen/rijndael/rijndael-fst-3.0.zip.
 * To use a different implementation, use these definitions as a model.
 * ----------------------------------------------------------------------- */
#if VMAC_USE_OPENSSL

#include <openssl/aes.h>
typedef AES_KEY aes_int_key;

#define aes_encryption(in,out,int_key)                  \
	    	AES_encrypt((unsigned char *)(in),(unsigned char *)(out),(int_key))
#define aes_key_setup(key,int_key)                      \
	    	AES_set_encrypt_key((key),VMAC_KEY_LEN,(int_key))

#else

//#include "rijndael-alg-fst.h"
typedef uint64_t  vmac_t;
#include "rijndael.h"
typedef u32 aes_int_key[4*(VMAC_KEY_LEN/32+7)];

#define aes_encryption(in,out,int_key)                  \
	    	rijndaelEncrypt((u32 *)(int_key),           \
	                        ((VMAC_KEY_LEN/32)+6),      \
	    				    (u8 *)(in), (u8 *)(out))
#define aes_key_setup(user_key,int_key)                 \
	    	rijndaelKeySetupEnc((u32 *)(int_key),       \
	    	                    (u8 *)(user_key), \
	    	                    VMAC_KEY_LEN)
#endif

/* --------------------------------------------------------------------- */

typedef struct {
	uint64_t nhkey  [(VMAC_NHBYTES/8)+2*(VMAC_TAG_LEN/64-1)];
	uint64_t polykey[2*VMAC_TAG_LEN/64];
	uint64_t l3key  [2*VMAC_TAG_LEN/64];
	uint64_t polytmp[2*VMAC_TAG_LEN/64];
	aes_int_key cipher_key;
	#if (VMAC_TAG_LEN == 64) && (VMAC_CACHE_NONCES)
	uint64_t cached_nonce[2];
	uint64_t cached_aes[2];
	#endif
	int first_block_processed;
} vmac_ctx_t;

/* --------------------------------------------------------------------- */
#ifdef  __cplusplus
extern "C" {
#endif
/* --------------------------------------------------------------------------
 *                        <<<<< USAGE NOTES >>>>>
 *
 * Given msg m (mbytes in length) and nonce buffer n
 * this function returns a tag as its output. The tag is returned as
 * a number. When VMAC_TAG_LEN == 64, the 'return'ed integer is the tag,
 * and *tagl is meaningless. When VMAC_TAG_LEN == 128 the tag is the
 * number y * 2^64 + *tagl where y is the function's return value.
 * If you want to consider tags to be strings, then you must do so with
 * an agreed upon endian orientation for interoperability, and convert
 * the results appropriately. VHASH hashes m without creating any tag.
 * Consecutive substrings forming a prefix of a message may be passed
 * to vhash_update, with vhash or vmac being called with the remainder
 * to produce the output.
 *
 * Requirements:
 * - On 32-bit architectures with SSE2 instructions, ctx and m MUST be
 *   begin on 16-byte memory boundaries.
 * - m MUST be your message followed by zeroes to the nearest 16-byte
 *   boundary. If m is a length multiple of 16 bytes, then it is already
 *   at a 16-byte boundary and needs no padding. mbytes should be your
 *   message length without any padding. 
 * - The first bit of the nonce buffer n must be 0. An i byte nonce, is made
 *   as the first 16-i bytes of n being zero, and the final i the nonce.
 * - vhash_update MUST have mbytes be a positive multiple of VMAC_NHBYTES
 * ----------------------------------------------------------------------- */

#define vmac_update vhash_update

void vhash_update(unsigned char m[],
          unsigned int mbytes,
          vmac_ctx_t *ctx);

uint64_t vmac(unsigned char m[],
         unsigned int mbytes,
         unsigned char n[16],
         uint64_t *tagl,
         vmac_ctx_t *ctx);

uint64_t vhash(unsigned char m[],
          unsigned int mbytes,
          uint64_t *tagl,
          vmac_ctx_t *ctx);

/* --------------------------------------------------------------------------
 * When passed a VMAC_KEY_LEN bit user_key, this function initialazies ctx.
 * ----------------------------------------------------------------------- */

void vmac_set_key(unsigned char user_key[], vmac_ctx_t *ctx);

/* --------------------------------------------------------------------------
 * This function aborts current hash and resets ctx, ready for a new message.
 * ----------------------------------------------------------------------- */

void vhash_abort(vmac_ctx_t *ctx);

/* --------------------------------------------------------------------- */

#ifdef  __cplusplus
}
#endif

#endif /* HEADER_AES_H */
