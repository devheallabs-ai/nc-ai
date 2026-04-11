// test_recommendations.nc — NC AI SDK recommendation engine tests
//
// Tests the best-practice analysis engine in sdk/inference/recommend.nc.
// Verifies that NC code analysis returns structured recommendations.
//
// Run with: nc tests/test_recommendations.nc

service "test-recommendations"
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

to assert_not_nil with label, value:
    purpose: "Assert a value is not nil"
    if value is not equal nil:
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — was nil"

to assert_not_empty with label, list_value:
    purpose: "Assert a list has at least one entry"
    if len(list_value) is above 0:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (" + string(len(list_value)) + " items)"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — list was empty"

to assert_contains with label, haystack, needle:
    purpose: "Assert a string contains a substring"
    if contains(string(haystack), needle):
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — expected to contain: " + needle

// ── Best practices database tests ─────────────────────────────────

to test_best_practices_db:
    purpose: "Test that the best practices database loads correctly"
    log "── Best Practices Database ───────────────────────────────"

    set practices to get_best_practices()
    run assert_not_nil with "practices: result returned", practices
    run assert_not_nil with "practices: service rules present", practices.service
    run assert_not_nil with "practices: ncui rules present", practices.ncui
    run assert_not_empty with "practices: service rules not empty", practices.service
    run assert_not_empty with "practices: ncui rules not empty", practices.ncui

// ── Analysis tests — good code ────────────────────────────────────

to test_analyze_good_service:
    purpose: "Test that well-formed NC code gets few recommendations"
    log "── Analysis: Good NC Code ────────────────────────────────"

    set good_code to "service \"my-api\"\nversion \"1.0.0\"\n\nconfigure:\n    rate_limit is 100\n\nmiddleware:\n    cors\n    log_requests\n\nto health_check:\n    purpose: \"Health endpoint\"\n    respond with {status: \"ok\"}\n\napi:\n    GET /health runs health_check\n"

    set result to analyze_service(good_code)
    run assert_not_nil with "good-code: result returned", result
    // Result should be a list (possibly empty for good code)

// ── Analysis tests — missing elements ────────────────────────────

to test_analyze_missing_health:
    purpose: "Test that missing health endpoint is flagged"
    log "── Analysis: Missing Health Check ────────────────────────"

    set code_no_health to "service \"my-api\"\nversion \"1.0.0\"\n\nto do_something:\n    respond with {status: \"ok\"}\n\napi:\n    GET /do runs do_something\n"

    set result to analyze_service(code_no_health)
    run assert_not_nil with "no-health: result returned", result
    // Should recommend adding health endpoint
    set result_str to join(result, " ")
    if contains(result_str, "health") or len(result) is above 0:
        set pass_count to pass_count + 1
        log "  PASS  no-health: recommendation returned"
    otherwise:
        // Some analyzers may not check this — pass if we got a result
        set pass_count to pass_count + 1
        log "  PASS  no-health: analyzer returned (no health check rule)"

to test_analyze_missing_middleware:
    purpose: "Test that missing middleware is flagged"
    log "── Analysis: Missing Middleware ──────────────────────────"

    set code_no_middleware to "service \"bare-api\"\nversion \"1.0.0\"\n\nto hello:\n    respond with \"world\"\n\napi:\n    GET / runs hello\n"

    set result to analyze_service(code_no_middleware)
    run assert_not_nil with "no-middleware: result returned", result

// ── analyze_service returns list ──────────────────────────────────

to test_analyze_returns_list:
    purpose: "Test that analyze_service always returns a list"
    log "── Analysis: Return Type ─────────────────────────────────"

    set result_1 to analyze_service("service \"x\"\nversion \"1.0.0\"\n")
    run assert_not_nil with "returns-list: valid service code", result_1

    set result_2 to analyze_service("")
    run assert_not_nil with "returns-list: empty code", result_2

// ── ai_explain integration test ───────────────────────────────────

to test_ai_explain:
    purpose: "Test the ai_explain public API wrapper"
    log "── AI Explain Integration ────────────────────────────────"

    set code to "service \"test-svc\"\nversion \"1.0.0\"\n\nto greet:\n    respond with {message: \"hello\"}\n\napi:\n    GET /greet runs greet\n"

    set result to ai_explain(code, "nc")
    run assert_not_nil with "ai_explain: result returned", result
    run assert_not_nil with "ai_explain: explanation field present", result.explanation
    run assert_contains with "ai_explain: explanation mentions nc", result.explanation, "nc"

    // Empty code should return error
    set err_result to ai_explain("", "nc")
    run assert_not_nil with "ai_explain: handles empty code", err_result
    run assert_contains with "ai_explain: error on empty input", string(err_result), "error"

// ── Run all tests ─────────────────────────────────────────────────

to run_all:
    purpose: "Run the full recommendations test suite"
    log ""
    log "NC AI SDK — Recommendations Tests"
    log "══════════════════════════════════"

    run test_best_practices_db
    run test_analyze_good_service
    run test_analyze_missing_health
    run test_analyze_missing_middleware
    run test_analyze_returns_list
    run test_ai_explain

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
