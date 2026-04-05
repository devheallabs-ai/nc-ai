// test_reasoning.nc — NC AI SDK graph reasoning tests
//
// Tests the multi-hop weighted reasoning engine in sdk/ml/reasoning.nc.
// Verifies path generation, scoring, beam search, and transitive closure.
//
// Run with: nc tests/test_reasoning.nc

service "test-reasoning"
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
    purpose: "Assert a numeric value is above a threshold"
    if value is above threshold:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (" + string(value) + " > " + string(threshold) + ")"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — " + string(value) + " not above " + string(threshold)

to assert_not_nil with label, value:
    purpose: "Assert a value is not nil"
    if value is not equal nil:
        set pass_count to pass_count + 1
        log "  PASS  " + label
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — was nil"

to assert_not_empty with label, list_value:
    purpose: "Assert a list is not empty"
    if len(list_value) is above 0:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (length: " + string(len(list_value)) + ")"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — list was empty"

// ── Build a test knowledge graph ──────────────────────────────────

to build_test_graph:
    purpose: "Build a small test knowledge graph for reasoning tests"
    set graph to {
        "cat": [
            {target: "mammal", weight: 0.9, relation: "is"},
            {target: "animal", weight: 0.8, relation: "is"},
            {target: "fur", weight: 0.7, relation: "has"}
        ],
        "mammal": [
            {target: "animal", weight: 0.95, relation: "is"},
            {target: "warm-blooded", weight: 0.9, relation: "is"}
        ],
        "animal": [
            {target: "living", weight: 0.99, relation: "is"}
        ],
        "dog": [
            {target: "mammal", weight: 0.9, relation: "is"},
            {target: "animal", weight: 0.8, relation: "is"},
            {target: "loyal", weight: 0.85, relation: "has"}
        ]
    }
    respond with graph

// ── Node validity tests ───────────────────────────────────────────

to test_valid_node:
    purpose: "Test the node validity constraint checker"
    log "── Node Validity ─────────────────────────────────────────"

    set result_valid to valid_node("mammal")
    run assert_equal with "valid_node: 'mammal' is valid", result_valid, true

    set result_short to valid_node("is")
    run assert_equal with "valid_node: 'is' is stop word (invalid)", result_short, false

    set result_the to valid_node("the")
    run assert_equal with "valid_node: 'the' is stop word (invalid)", result_the, false

    set result_single to valid_node("a")
    run assert_equal with "valid_node: single char is invalid", result_single, false

// ── Path generation tests ─────────────────────────────────────────

to test_path_generation:
    purpose: "Test multi-hop path generation from a start node"
    log "── Path Generation ───────────────────────────────────────"

    set graph to build_test_graph()
    set paths to generate_paths("cat", graph, 2)
    run assert_not_nil with "paths: result returned", paths
    run assert_not_empty with "paths: at least one path generated", paths

    // Paths should start with cat
    set first_path to paths[0]
    set first_node to first_path[0]
    run assert_equal with "paths: first node is start node", first_node.node, "cat"

// ── Path scoring tests ────────────────────────────────────────────

to test_path_scoring:
    purpose: "Test that paths are scored correctly"
    log "── Path Scoring ──────────────────────────────────────────"

    set simple_path to [
        {node: "cat", weight: 1.0, relation: "start"},
        {node: "mammal", weight: 0.9, relation: "is"},
        {node: "animal", weight: 0.95, relation: "is"}
    ]

    set score to path_score(simple_path)
    run assert_not_nil with "scoring: score returned", score
    // Score should be positive (path has positive weights)
    run assert_above with "scoring: positive score for valid path", score, 0.0

// ── Best path tests ───────────────────────────────────────────────

to test_best_path:
    purpose: "Test that best_path returns a valid path"
    log "── Best Path ─────────────────────────────────────────────"

    set graph to build_test_graph()
    set best to best_path("cat", graph, 3)
    run assert_not_nil with "best_path: result returned", best
    run assert_not_empty with "best_path: path is not empty", best

    set first_step to best[0]
    run assert_equal with "best_path: starts at 'cat'", first_step.node, "cat"

// ── Transitive closure tests ──────────────────────────────────────

to test_transitive_closure:
    purpose: "Test reachability via transitive inference"
    log "── Transitive Closure ────────────────────────────────────"

    set graph to build_test_graph()
    set reachable to transitive_closure("cat", graph, 3)
    run assert_not_nil with "closure: result returned", reachable

    // From 'cat' we should reach 'mammal', 'animal', 'living', etc.
    set reached_mammal to get(reachable, "mammal")
    run assert_not_nil with "closure: cat → mammal reachable", reached_mammal

// ── Modus ponens tests ────────────────────────────────────────────

to test_modus_ponens:
    purpose: "Test symbolic modus ponens inference"
    log "── Modus Ponens ──────────────────────────────────────────"

    set rules to [
        {antecedent: "cat", consequent: "animal"},
        {antecedent: "cat", consequent: "pet"},
        {antecedent: "animal", consequent: "living"}
    ]

    set inferred to modus_ponens(rules, "cat")
    run assert_not_nil with "modus_ponens: result returned", inferred
    run assert_not_empty with "modus_ponens: inferences made from 'cat'", inferred

    // Should infer "animal" and "pet" from "cat"
    set found_animal to false
    repeat for each i in inferred:
        if i is equal "animal":
            set found_animal to true
    if found_animal:
        set pass_count to pass_count + 1
        log "  PASS  modus_ponens: inferred 'animal' from 'cat'"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  modus_ponens: did not infer 'animal' from 'cat'"

// ── ai_reason integration test ────────────────────────────────────

to test_ai_reason:
    purpose: "Test the ai_reason public API wrapper"
    log "── AI Reason Integration ─────────────────────────────────"

    set result to ai_reason("Why do cats eat fish?", "")
    run assert_not_nil with "ai_reason: result returned", result
    run assert_not_nil with "ai_reason: answer present", result.answer
    run assert_not_nil with "ai_reason: confidence present", result.confidence

    // Empty question should return error
    set err_result to ai_reason("", "")
    run assert_not_nil with "ai_reason: handles empty question", err_result

// ── Run all tests ─────────────────────────────────────────────────

to run_all:
    purpose: "Run the full reasoning test suite"
    log ""
    log "NC AI SDK — Reasoning Tests"
    log "══════════════════════════════════"

    run test_valid_node
    run test_path_generation
    run test_path_scoring
    run test_best_path
    run test_transitive_closure
    run test_modus_ponens
    run test_ai_reason

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
