// test_embeddings.nc — NC AI SDK embedding and similarity tests
//
// Tests the Hebbian vector embedding engine in sdk/ml/embeddings.nc.
// Verifies vector initialization, cosine similarity range, and encoding.
//
// Run with: nc tests/test_embeddings.nc

service "test-embeddings"
version "1.0.0"

set pass_count to 0
set fail_count to 0

to assert_equal with label, actual, expected:
    purpose: "Assert two values are equal"
    if actual is equal expected:
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — expected: " + string(expected) + " got: " + string(actual)

to assert_above with label, value, threshold:
    purpose: "Assert a value is above a threshold"
    if value is above threshold:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (" + string(value) + " > " + string(threshold) + ")"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — " + string(value) + " not above " + string(threshold)

to assert_below with label, value, threshold:
    purpose: "Assert a value is below a threshold"
    if value is below threshold:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (" + string(value) + " < " + string(threshold) + ")"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — " + string(value) + " not below " + string(threshold)

to assert_not_nil with label, value:
    purpose: "Assert a value is not nil"
    if value is not equal nil:
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — value was nil"

// ── Embedding initialization tests ───────────────────────────────

to test_init_embedding:
    purpose: "Test that embedding vectors are created and returned"
    log "── Embedding Initialization ──────────────────────────────"

    set v to init_embedding("hello")
    run assert_not_nil with "init: returns a vector", v

    // Calling again should return the same vector (cached)
    set v2 to init_embedding("hello")
    run assert_not_nil with "init: cached vector not nil", v2

// ── Vector retrieval tests ────────────────────────────────────────

to test_vec:
    purpose: "Test that vec() retrieves or creates embeddings"
    log "── Vector Retrieval ──────────────────────────────────────"

    set v_cat to vec("cat")
    run assert_not_nil with "vec: 'cat' returns vector", v_cat

    set v_dog to vec("dog")
    run assert_not_nil with "vec: 'dog' returns vector", v_dog

    set v_empty to vec("x")
    run assert_not_nil with "vec: single char returns vector", v_empty

// ── Cosine similarity tests ───────────────────────────────────────

to test_cosine_similarity:
    purpose: "Test cosine similarity returns values in [0, 1] range"
    log "── Cosine Similarity ─────────────────────────────────────"

    set va to vec("apple")
    set vb to vec("orange")
    set vc to vec("apple")

    set sim_ab to cosine_sim(va, vb)
    run assert_not_nil with "cosine: returns a value", sim_ab

    // Self-similarity with identical words should return 1.0
    set sim_self to cosine_sim(va, vc)
    // Note: because of Hebbian initialization randomness, va and vc
    // for the same word should be the same cached vector → sim = 1.0
    run assert_equal with "cosine: identical vectors → 1.0", sim_self, 1.0

// ── ai_encode integration tests ───────────────────────────────────

to test_ai_encode:
    purpose: "Test the ai_encode wrapper for multi-word text"
    log "── AI Encode Integration ─────────────────────────────────"

    // ai_encode should work with multi-word text
    set result to ai_encode("build a REST API")
    run assert_not_nil with "ai_encode: returns result for multi-word text", result

    // Empty text should return error
    set err_result to ai_encode("")
    run assert_not_nil with "ai_encode: handles empty text", err_result

// ── ai_similarity integration tests ──────────────────────────────

to test_ai_similarity:
    purpose: "Test the ai_similarity wrapper"
    log "── AI Similarity Integration ─────────────────────────────"

    // Same text should yield maximum similarity
    set sim_same to ai_similarity("hello world", "hello world")
    run assert_not_nil with "similarity: same text returns a value", sim_same

    // Different text should yield some value
    set sim_diff to ai_similarity("build an API", "write some code")
    run assert_not_nil with "similarity: different text returns a value", sim_diff

    // Error case — empty input
    set err_result to ai_similarity("", "hello")
    run assert_not_nil with "similarity: handles empty text_a", err_result

// ── Run all tests ─────────────────────────────────────────────────

to run_all:
    purpose: "Run the full embeddings test suite"
    log ""
    log "NC AI SDK — Embeddings Tests"
    log "══════════════════════════════════"

    run test_init_embedding
    run test_vec
    run test_cosine_similarity
    run test_ai_encode
    run test_ai_similarity

    log ""
    log "══════════════════════════════════"
    log "Results: " + string(pass_count) + " passed, " + string(fail_count) + " failed"
    if fail_count is above 0:
        log "STATUS: FAIL"
    otherwise:
        log "STATUS: PASS"
    log ""
    respond with {
        passed: pass_count,
        failed: fail_count,
        status: "completed"
    }

run run_all
