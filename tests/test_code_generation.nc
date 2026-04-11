// test_code_generation.nc — NC AI SDK code generation tests
//
// Tests the deterministic intent detection and template-based code generation
// in sdk/nc_ai_api.nc and sdk/inference/generate.nc.
//
// Run with: nc tests/test_code_generation.nc

service "test-code-generation"
version "1.0.0"

set pass_count to 0
set fail_count to 0

to assert_equal with label, actual, expected:
    purpose: "Assert two values are equal and report result"
    if actual is equal expected:
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — expected: " + string(expected) + " got: " + string(actual)

to assert_contains with label, haystack, needle:
    purpose: "Assert a string contains a substring"
    if contains(string(haystack), needle):
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — expected to contain: " + needle

to assert_not_empty with label, value:
    purpose: "Assert a value is not empty"
    if value is not equal nil:
        if len(string(value)) is above 0:
            set pass_count to pass_count + 1
            log "  PASS  " + label
            respond with true
    set fail_count to fail_count + 1
    log "  FAIL  " + label + " — value was empty or nil"

// ── Intent detection tests ────────────────────────────────────────

to test_intent_detection:
    purpose: "Test that prompts classify to correct intents"
    log "── Intent Detection ──────────────────────────────────────"

    // CRUD intent
    set result_crud to detect_intent("Build a CRUD API for products")
    run assert_equal with "crud: database prompt", result_crud.intent, "crud"

    set result_crud2 to detect_intent("create a database service for users")
    run assert_equal with "crud: create database prompt", result_crud2.intent, "crud"

    // Chatbot intent
    set result_chat to detect_intent("Build a chat assistant")
    run assert_equal with "chatbot: chat prompt", result_chat.intent, "chatbot"

    set result_conv to detect_intent("create a conversation bot")
    run assert_equal with "chatbot: conversation prompt", result_conv.intent, "chatbot"

    // Summarizer intent
    set result_sum to detect_intent("summarize text documents")
    run assert_equal with "summarizer: summarize prompt", result_sum.intent, "summarizer"

    // Pipeline intent
    set result_pipe to detect_intent("build an ETL pipeline")
    run assert_equal with "pipeline: etl prompt", result_pipe.intent, "pipeline"

    // Default service intent
    set result_svc to detect_intent("create a hello world service")
    run assert_equal with "service: default intent", result_svc.intent, "service"

    // Webhook intent
    set result_wh to detect_intent("create a webhook endpoint for events")
    run assert_equal with "webhook: event prompt", result_wh.intent, "webhook"

// ── Feature detection tests ───────────────────────────────────────

to test_feature_detection:
    purpose: "Test that features are correctly detected from prompts"
    log "── Feature Detection ─────────────────────────────────────"

    set result_auth to detect_intent("build a service with JWT auth and login")
    run assert_contains with "auth feature detected", join(result_auth.features, ","), "auth"

    set result_ai to detect_intent("build an intelligent AI service")
    run assert_contains with "ai feature detected", join(result_ai.features, ","), "ai"

    set result_cache to detect_intent("build a caching service with redis")
    run assert_contains with "cache feature detected", join(result_cache.features, ","), "cache"

    set result_search to detect_intent("build a search query API")
    run assert_contains with "search feature detected", join(result_search.features, ","), "search"

    set result_notify to detect_intent("build a notification email service")
    run assert_contains with "notification feature detected", join(result_notify.features, ","), "notification"

// ── Generated code quality tests ──────────────────────────────────

to test_generated_code:
    purpose: "Test that generated code contains expected NC patterns"
    log "── Generated Code Quality ────────────────────────────────"

    // CRUD should produce to create/list_all/get_one functions
    set crud_intent to detect_intent("build a product CRUD API")
    set crud_code to generate_from_template(crud_intent.intent, crud_intent.name, crud_intent.features)
    run assert_contains with "crud: service declaration", crud_code, "service"
    run assert_contains with "crud: create function", crud_code, "to create"
    run assert_contains with "crud: list function", crud_code, "to list_all"
    run assert_contains with "crud: api block", crud_code, "api:"
    run assert_contains with "crud: health endpoint", crud_code, "health"

    // Chatbot should produce a chat function
    set chat_intent to detect_intent("build a chat assistant")
    set chat_code to generate_from_template(chat_intent.intent, chat_intent.name, chat_intent.features)
    run assert_contains with "chatbot: service declaration", chat_code, "service"
    run assert_contains with "chatbot: chat function", chat_code, "to chat"

    // Default service should have a basic structure
    set svc_intent to detect_intent("create a hello service")
    set svc_code to generate_from_template(svc_intent.intent, svc_intent.name, svc_intent.features)
    run assert_contains with "service: version declaration", svc_code, "version"

// ── Edge case tests ───────────────────────────────────────────────

to test_edge_cases:
    purpose: "Test edge cases in generation"
    log "── Edge Cases ────────────────────────────────────────────"

    // Very short prompt
    set short_result to detect_intent("api")
    run assert_not_empty with "short prompt: returns intent", short_result.intent

    // Mixed case prompt
    set mixed_result to detect_intent("BUILD A CRUD DATABASE SERVICE")
    run assert_equal with "uppercase prompt: crud intent", mixed_result.intent, "crud"

    // Multiple features in one prompt
    set multi_result to detect_intent("build an authenticated AI search service with rate limiting")
    set features_str to join(multi_result.features, ",")
    run assert_contains with "multi-feature: auth", features_str, "auth"
    run assert_contains with "multi-feature: ai", features_str, "ai"
    run assert_contains with "multi-feature: search", features_str, "search"
    run assert_contains with "multi-feature: rate_limit", features_str, "rate_limit"

// ── Run all tests ─────────────────────────────────────────────────

to run_all:
    purpose: "Run the full code generation test suite"
    log ""
    log "NC AI SDK — Code Generation Tests"
    log "══════════════════════════════════"

    run test_intent_detection
    run test_feature_detection
    run test_generated_code
    run test_edge_cases

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
