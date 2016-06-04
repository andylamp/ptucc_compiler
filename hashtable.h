/**
 * This is a no-nonsense hash-table implementation; it's simple
 * and small. Also we won't allow duplicate keys, if a key is found
 * then its value is replaced with the new one instead.
 *
 * It's reasonably fast and for the needs and purposes of
 * a simple (Key, Value) store which handles strings or
 * bytes it's OK.
 */

#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

/* hash table entry structure */
typedef struct ht_entry {
    char *key;              // our key.
    char *value;            // our hash table value.
    struct ht_entry *next;  // our next pointer.
} ht_entry_t;

/* hash table structure */
typedef struct hashtable_s {
    size_t size;                            // hash table size (in bins).
    size_t stored_elements;                 // currently stored elements.
    struct ht_entry **table;                // array with bin pointers.
    uint32_t (*hash_func)(size_t, char *);  // hash function.
} hashtable_t;

/**
 * Hash a key to one of our bins.
 */
uint32_t ht_hash(size_t tab_size, char *key);

/**
 * Bob jenkins fast hash function.
 */
uint32_t ht_hash_jenkins(size_t tab_size, char *key);


/**
 * Initialize our hash table.
 */
hashtable_t *ht_create(size_t tab_size,
                       uint32_t (*hash_func)(size_t, char *));

/**
 * Create a key-value pair with error-checking.
 */
ht_entry_t *ht_newpair(char *key, char *value);

/**
 * Insert a key-value pair into a hash table.
 */
bool ht_set(hashtable_t *ht, char *key, char *value);

/**
 * Retrieve a key-value pair from a hash table.
 * */
char *ht_get(hashtable_t *ht, char *key);

/**
 * Removes an entry from the hash table freeing the key and
 * the respective node as well -- only if that bin has more than
 * one entries.
 */
char *ht_rem(hashtable_t *ht, char *key);

/**
 * Destroy the hash table data structure along with
 * its entries.
 */
bool ht_destroy(hashtable_t *ht);
