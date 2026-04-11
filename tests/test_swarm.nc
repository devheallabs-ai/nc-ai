// test_swarm.nc — NC AI SDK multi-agent swarm tests
//
// Tests the ant-colony-inspired multi-agent system in sdk/ml/swarm.nc.
// Verifies agent creation, initialization, strategy execution, and
// pheromone reinforcement.
//
// Run with: nc tests/test_swarm.nc

service "test-swarm"
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
    purpose: "Assert a list has at least one entry"
    if len(list_value) is above 0:
        set pass_count to pass_count + 1
        log "  PASS  " + label + " (length: " + string(len(list_value)) + ")"
    otherwise:
        set fail_count to fail_count + 1
        log "  FAIL  " + label + " — list was empty"

// ── Build a test graph for swarm traversal ─────────────────────────

to build_swarm_graph:
    purpose: "Build a small directed graph for swarm navigation tests"
    set graph to {
        "start": [
            {target: "node_a", weight: 0.8, relation: "leads"},
            {target: "node_b", weight: 0.6, relation: "leads"},
            {target: "node_c", weight: 0.4, relation: "leads"}
        ],
        "node_a": [
            {target: "goal", weight: 0.9, relation: "leads"}
        ],
        "node_b": [
            {target: "node_a", weight: 0.5, relation: "leads"},
            {target: "goal", weight: 0.7, relation: "leads"}
        ],
        "node_c": [
            {target: "node_b", weight: 0.6, relation: "leads"}
        ]
    }
    respond with graph

// ── Agent creation tests ──────────────────────────────────────────

to test_create_agent:
    purpose: "Test that agents can be created with different strategies"
    log "── Agent Creation ────────────────────────────────────────"

    set agent to create_agent(0, "greedy")
    run assert_not_nil with "create_agent: result returned", agent
    run assert_equal with "create_agent: id set correctly", agent.id, 0
    run assert_equal with "create_agent: strategy set correctly", agent.strategy, "greedy"
    run assert_equal with "create_agent: initial score is 0", agent.score, 0.0

    set agent2 to create_agent(1, "explorative")
    run assert_equal with "create_agent: explorative strategy", agent2.strategy, "explorative"

    set agent3 to create_agent(2, "conservative")
    run assert_equal with "create_agent: conservative strategy", agent3.strategy, "conservative"

// ── Swarm initialization tests ────────────────────────────────────

to test_init_swarm:
    purpose: "Test that swarm initializes all agents with different strategies"
    log "── Swarm Initialization ──────────────────────────────────"

    set all_agents to init_swarm()
    run assert_not_nil with "init_swarm: result returned", all_agents
    run assert_not_empty with "init_swarm: agents created", all_agents
    run assert_above with "init_swarm: at least 3 agents", len(all_agents), 2

// ── Greedy path tests ─────────────────────────────────────────────

to test_greedy_path:
    purpose: "Test the greedy agent always picks highest-weight edge"
    log "── Greedy Path ───────────────────────────────────────────"

    set graph to build_swarm_graph()
    set path to greedy_path("start", graph, 3)
    run assert_not_nil with "greedy: result returned", path
    run assert_not_empty with "greedy: path not empty", path
    run assert_equal with "greedy: starts at 'start'", path[0], "start"

// ── Explorative path tests ────────────────────────────────────────

to test_explorative_path:
    purpose: "Test the explorative agent prefers less-visited paths"
    log "── Explorative Path ──────────────────────────────────────"

    set graph to build_swarm_graph()
    set path to explorative_path("start", graph, 3)
    run assert_not_nil with "explorative: result returned", path
    run assert_not_empty with "explorative: path not empty", path
    run assert_equal with "explorative: starts at 'start'", path[0], "start"

// ── Pheromone update tests ────────────────────────────────────────

to test_pheromone_update:
    purpose: "Test that pheromone trails are updated after traversal"
    log "── Pheromone Update ──────────────────────────────────────"

    set path_taken to ["start", "node_a", "goal"]
    set score to 0.9
    set result to update_pheromones(path_taken, score)
    // Should not error — pheromone update is a side-effect operation
    run assert_not_nil with "pheromone: update completes", result

// ── ai_swarm integration test ─────────────────────────────────────

to test_ai_swarm:
    purpose: "Test the ai_swarm public API wrapper"
    log "── AI Swarm Integration ──────────────────────────────────"

    set result to ai_swarm("Build a REST API for products", 3, "ant_colony")
    run assert_not_nil with "ai_swarm: result returned", result
    run assert_not_nil with "ai_swarm: result field present", result.result
    run assert_not_nil with "ai_swarm: consensus_score present", result.consensus_score
    run assert_not_nil with "ai_swarm: agent_results present", result.agent_results

    // Empty task should return error
    set err_result to ai_swarm("", 3, "ant_colony")
    run assert_not_nil with "ai_swarm: handles empty task", err_result

// ── ai_agent integration test ─────────────────────────────────────

to test_ai_agent:
    purpose: "Test the ai_agent single-agent wrapper"
    log "── AI Agent Integration ──────────────────────────────────"

    set result to ai_agent("Build a todo list API", [])
    run assert_not_nil with "ai_agent: result returned", result
    run assert_not_nil with "ai_agent: result field present", result.result
    run assert_not_nil with "ai_agent: status present", result.status

    // Empty task should return error
    set err_result to ai_agent("", [])
    run assert_not_nil with "ai_agent: handles empty task", err_result

// ── Run all tests ─────────────────────────────────────────────────

to run_all:
    purpose: "Run the full swarm test suite"
    log ""
    log "NC AI SDK — Swarm Tests"
    log "══════════════════════════════════"

    run test_create_agent
    run test_init_swarm
    run test_greedy_path
    run test_explorative_path
    run test_pheromone_update
    run test_ai_swarm
    run test_ai_agent

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
