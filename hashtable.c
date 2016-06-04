/**
 * This is a no-nonsense hash-table implementation; it's simple
 * and small. Also we won't allow duplicate keys, if a key is found
 * then its value is replaced with the new one instead.
 *
 * It's reasonably fast and for the needs and purposes of
 * a simple (Key, Value) store which handles strings or
 * bytes it's OK.
 */

#include "hashtable.h"

/**
 * Hash a key to one of our bins.
 */
uint32_t ht_hash(size_t tab_size, char *key) {

    uint64_t hash = 0;
    int i = 0;
    ssize_t klen = strlen(key);

    /* error checking */
    if (tab_size < 1 || key == NULL) { return 0; }

    /* hash the key -> uint */
    while (hash < ULONG_MAX && i < klen) {
        hash = hash << 8;
        hash += key[i];
        i++;
    }
    /* confine the result to a specific bin */
    return (uint32_t)(hash % tab_size);
}

/**
 * Bob jenkins fast hash function.
 */
uint32_t ht_hash_jenkins(size_t tab_size, char *key) {
    uint32_t hash,                  // hash value
            i;                     // iter
    ssize_t klen = strlen(key);     // key length
    /* error checking */
    if (tab_size < 1 || key == NULL) { return 0; }

    /* loop for each of the bytes in the key */
    for (hash = i = 0; i < klen; ++i) {
        /* jenkins magic */
        hash += key[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    /* more jenkins magic */
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    /* confine the result to one of our bins */
    return (uint32_t)(hash % tab_size);
}


/**
 * Initialize our hash table.
 */
hashtable_t *ht_create(size_t tab_size,
                       uint32_t (*hash_func)(size_t, char *)) {

    hashtable_t *ht = NULL;
    int i;

    /* basic error checking */
    if (tab_size < 1) { return NULL; }

    /* allocate the hashtable data structure */
    if ((ht = (hashtable_t *) calloc(1, sizeof(*ht))) == NULL) { return NULL; }

    /* initialize the bin pointers. */
    if ((ht->table = (ht_entry_t **)
            calloc(tab_size, sizeof(*(ht->table)))) == NULL) {
        free(ht);
        return NULL;
    }

    /* nullify entries */
    for (i = 0; i < tab_size; i++) { ht->table[i] = NULL; }

    /* set the table size */
    ht->size = tab_size;

    /* initialize the element size */
    ht->stored_elements = 0;

    /* set the hash function */
    if (hash_func == NULL) { ht->hash_func = &ht_hash_jenkins; }
    else { ht->hash_func = hash_func; }
    /* finally return the hash table */
    return ht;
}

/**
 * Create a key-value pair with error-checking.
 */
ht_entry_t *ht_newpair(char *key, char *value) {
    ht_entry_t *newpair = NULL;
    // check for valid entries
    if (key == NULL || value == NULL) { return NULL; }

    /* create the actual node */
    if ((newpair = (ht_entry_t *) calloc(1, sizeof(*newpair))) == NULL) { return NULL; }
    /* copy the key */
    if ((newpair->key = strdup(key)) == NULL) {
        free(newpair);
        return NULL;
    }
    /* copy the value */
    if ((newpair->value = strdup(value)) == NULL) {
        free(newpair->key);
        free(newpair);
        return NULL;
    }

    newpair->next = NULL;

    return newpair;
}

/**
 * Insert a key-value pair into a hash table.
 */
bool ht_set(hashtable_t *ht, char *key, char *value) {
    int bin = 0;
    ht_entry_t *newpair = NULL;
    ht_entry_t *next = NULL;
    ht_entry_t *last = NULL;

    if (ht == NULL || key == NULL || value == NULL) { return false; }

    bin = ht->hash_func(ht->size, key);
    next = ht->table[bin];

    while (next != NULL &&
           next->key != NULL &&
           strcmp(key, next->key) > 0) {
        last = next;
        next = next->next;
    }

    /* There's already a pair.  Let's replace that string. */
    if (next != NULL &&
        next->key != NULL &&
        strcmp(key, next->key) == 0) {
        free(next->value);
        next->value = strdup(value);
        /* Nope, could't find it.  Time to grow a pair. */
    } else {
        /* increase element count */
        ht->stored_elements++;
        newpair = ht_newpair(key, value);

        /* We're at the start of the linked list in this bin. */
        if (next == ht->table[bin]) {
            newpair->next = next;
            ht->table[bin] = newpair;

            /* We're at the end of the linked list in this bin. */
        } else if (last != NULL && next == NULL) {
            last->next = newpair;

            /* We're in the middle of the list. */
        } else if (last != NULL) {
            newpair->next = next;
            last->next = newpair;
        } else {
            /* free the created pair, if any */
            if (newpair != NULL) {
                free(newpair->key);
                free(newpair->value);
                free(newpair);
            }
            /* decrease since we didn't store it */
            ht->stored_elements--;
            // error, last is null.
            return false;
        }
    }
    // OK.
    return true;
}

/**
 * Retrieve a key-value pair from a hash table.
 * */
char *ht_get(hashtable_t *ht, char *key) {
    int bin = 0;        // hash bin
    ht_entry_t *pair;   // pair pointer

    // error checking.
    if (ht == NULL || key == NULL) { return NULL; }

    /* hash the key to a bin. */
    bin = ht->hash_func(ht->size, key);

    /* Step through the bin, looking for our value. */
    pair = ht->table[bin];
    while (pair != NULL &&
           pair->key != NULL &&
           strcmp(key, pair->key) > 0) { pair = pair->next; }

    /* Did we actually find anything? */
    if (pair == NULL ||
        pair->key == NULL ||
        strcmp(key, pair->key) != 0) { return NULL; }
    else { return pair->value; }

}

/**
 * Removes an entry from the hash table freeing the key and
 * the respective node as well -- only if that bin has more than
 * one entries.
 */
char *ht_rem(hashtable_t *ht, char *key) {
    int bin = 0;            // value for the bin we end up
    ht_entry_t *next = NULL,// next entry in the hash table bin
            *last = NULL;// last entry in the hash table bin
    char *val = NULL;       // holds the removed value, null if not found.

    if (ht == NULL || key == NULL) { return NULL; }

    /* hash the key to an integer bucket number */
    bin = ht->hash_func(ht->size, key);
    /* initialize the next pointer to be the head of the found bin */
    next = ht->table[bin];

    while (next != NULL &&
           next->key != NULL &&
           strcmp(key, next->key) > 0) {
        last = next;
        next = next->next;
    }

    if (next != NULL &&
        next->key != NULL &&
        strcmp(key, next->key) == 0) {
        // found the key let's remove it.
        val = next->value;
        if (last == NULL) {
            free(next->key);
            next->key = NULL;
            next->value = NULL;
        } else {
            ht_entry_t *t = next;
            last->next = next->next;
            free(t->key);
            free(t);
        }
    }
    /* decrease elements */
    ht->stored_elements--;
    //printf("returning val: %s of key: %s", val == NULL ? "NULL" : val, key);
    // return the value or null.
    return val;
}

/**
 * Destroy the hash table data structure along with
 * its entries.
 */
bool ht_destroy(hashtable_t *ht) {
    ht_entry_t **ht_head = NULL,// head of table pointer
            *t_node = NULL; // points to a row of the table

    /* error checking */
    if (ht == NULL) { return false; }

    /* assign table pointer */
    ht_head = ht->table;

    /* delete each bin. */
    for (int i = 0; i < ht->size; i++) {
        /* assign the row to the pointer */
        ht_entry_t *h_row = ht_head[i];
        /* traverse the list in this bin and free its entries. */
        while (h_row != NULL) {
            t_node = h_row;
            h_row = h_row->next;
            if (t_node->key != NULL) { free(t_node->key); }
            if (t_node->value != NULL) { free(t_node->value); }
            free(t_node);
        }
    }
    /* finally free the hash table */
    free(ht_head);
    free(ht);
    return true;
}
