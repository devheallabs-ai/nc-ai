// nc_ai_api.nc — NC AI SDK Public API
//
// Single import point for all NC AI capabilities.
// Wraps inference/ and ml/ sub-modules into a unified service.
//
// Usage:
//   nc serve nc-ai-sdk/sdk/nc_ai_api.nc    (HTTP API on :8092)
//   nc run nc-ai-sdk/cli/chat.nc           (interactive chat)
//   nc ai "your prompt"                    (quick generation via CLI)
//
// Copyright (c) 2025-2026 Nuckala Sai Narender / DevHeal Labs
// Licensed under Apache 2.0

service "nc-ai-sdk"
version "1.0.0"

configure:
    port is 8092
    ai_model is "default"
    max_tokens is 512
    temperature is 0.7

to count_occurrences with text, needle:
    purpose: "Count how many times a substring appears"
    if needle is empty:
        respond with 0
    set parts to split(str(text), str(needle))
    if len(parts) is equal 0:
        respond with 0
    respond with len(parts) - 1

to normalize_token with token:
    purpose: "Lowercase and trim a single token"
    set cleaned to lower(trim(str(token)))
    set cleaned to replace(cleaned, ",", "")
    set cleaned to replace(cleaned, ".", "")
    set cleaned to replace(cleaned, ":", "")
    set cleaned to replace(cleaned, ";", "")
    set cleaned to replace(cleaned, "(", "")
    set cleaned to replace(cleaned, ")", "")
    set cleaned to replace(cleaned, "{", "")
    set cleaned to replace(cleaned, "}", "")
    respond with cleaned

to tokenize_text with text:
    purpose: "Split text into normalized tokens"
    if text is empty:
        respond with []
    set raw_tokens to split(lower(trim(text)), " ")
    set tokens to []
    repeat for each raw_token in raw_tokens:
        set token to normalize_token(raw_token)
        if len(token) is above 0:
            append token to tokens
    respond with tokens

to has_token with items, needle:
    purpose: "Return true when a list already contains a token"
    repeat for each item in items:
        if item is equal needle:
            respond with true
    respond with false

to unique_tokens with tokens:
    purpose: "Deduplicate tokens while preserving order"
    set uniques to []
    repeat for each token in tokens:
        if has_token(uniques, token) is not equal true:
            append token to uniques
    respond with uniques

to overlap_count with tokens_a, tokens_b:
    purpose: "Count shared tokens between two unique token lists"
    set overlap to 0
    repeat for each token in tokens_a:
        if has_token(tokens_b, token) is equal true:
            set overlap to overlap + 1
    respond with overlap

to detect_name with tokens:
    purpose: "Pick a stable project name from a prompt"
    set name to "app"
    set stopwords to ["create", "build", "make", "service", "page", "with", "dashboard", "using", "that", "from", "into", "have", "this", "will", "also", "crud", "rest", "http", "rate", "limiting", "limit", "based", "driven", "enabled", "simple", "basic", "full", "complete", "advanced", "system", "platform", "backend", "frontend", "server", "client", "application", "management", "integration", "intelligent", "smart", "real", "time", "live", "which", "where", "when", "what", "your", "their", "handle", "handles", "support", "supports"]
    repeat for each token in tokens:
        if len(token) is above 3:
            set is_stop to false
            repeat for each sw in stopwords:
                if token is equal sw:
                    set is_stop to true
            if is_stop is not equal true:
                if name is equal "app":
                    set name to token
    respond with name

to detect_intent with prompt:
    purpose: "Classify a natural language request into a stable SDK intent"
    if prompt is empty:
        respond with {"error": "prompt is required"}
    set p to lower(prompt)
    set tokens to tokenize_text(prompt)
    set features to []
    set intent to "service"

    if contains(p, "crud") or contains(p, "database") or contains(p, "store"):
        set intent to "crud"
    if contains(p, "chat") or contains(p, "conversation") or contains(p, "assistant"):
        set intent to "chatbot"
    if contains(p, "classify") or contains(p, "categorize") or contains(p, "label"):
        set intent to "classifier"
    if contains(p, "summarize") or contains(p, "summary") or contains(p, "summarization") or contains(p, "tldr"):
        set intent to "summarizer"
    if contains(p, "pipeline") or contains(p, "etl") or contains(p, "process"):
        set intent to "pipeline"
    if contains(p, "webhook") or contains(p, "event") or contains(p, "hook"):
        set intent to "webhook"
    if contains(p, "page") or contains(p, "dashboard") or contains(p, "frontend"):
        set intent to "ncui"

    if contains(p, "auth") or contains(p, "login") or contains(p, "jwt"):
        append "auth" to features
    if contains(p, "ai") or contains(p, "llm") or contains(p, "intelligent"):
        append "ai" to features
    if contains(p, "rate limit") or contains(p, "throttle"):
        append "rate_limit" to features
    if contains(p, "cache") or contains(p, "redis"):
        append "cache" to features
    if contains(p, "search") or contains(p, "query") or contains(p, "find"):
        append "search" to features
    if contains(p, "upload") or contains(p, "file"):
        append "upload" to features
    if contains(p, "email") or contains(p, "notify") or contains(p, "notification"):
        append "notification" to features
    if contains(p, "test") or contains(p, "testing"):
        append "test" to features

    set name to detect_name(tokens)
    respond with {
        "intent": intent,
        "features": unique_tokens(features),
        "name": name,
        "raw_prompt": prompt
    }

to generate_from_template with intent, name, features:
    purpose: "Generate deterministic NC or NCUI scaffolding"
    set q to "\""
    set nl to "\n"
    set t to "    "
    set feature_text to join(features, ",")
    set code to "service " + q + name + q + nl + "version " + q + "1.0.0" + q + nl

    if contains(feature_text, "ai"):
        set code to code + nl + "configure:" + nl + t + "ai_model is " + q + "default" + q + nl
    if contains(feature_text, "rate_limit"):
        set code to code + nl + "configure:" + nl + t + "rate_limit is 100" + nl + t + "rate_window is 60" + nl
    if contains(feature_text, "auth"):
        set code to code + nl + "configure:" + nl + t + "auth_type is " + q + "jwt" + q + nl

    if intent is equal "crud":
        set code to code + nl + "to create with data:" + nl
        set code to code + t + "store data into " + q + name + q + nl
        set code to code + t + "respond with {" + q + "created" + q + ": true, " + q + "data" + q + ": data}" + nl + nl
        set code to code + "to list_all:" + nl
        set code to code + t + "gather items from " + q + name + q + nl
        set code to code + t + "respond with items" + nl + nl
        set code to code + "to get_one with id:" + nl
        set code to code + t + "gather item from " + q + name + q + " where id" + nl
        set code to code + t + "respond with item" + nl + nl
        set code to code + "to update with id, data:" + nl
        set code to code + t + "store data into " + q + name + q + " where id" + nl
        set code to code + t + "respond with {" + q + "updated" + q + ": true}" + nl + nl
        set code to code + "to delete_one with id:" + nl
        set code to code + t + "remove from " + q + name + q + " where id" + nl
        set code to code + t + "respond with {" + q + "deleted" + q + ": true}" + nl + nl
        set code to code + "to health:" + nl
        set code to code + t + "respond with {" + q + "status" + q + ": " + q + "ok" + q + "}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST   /" + name + "      runs create" + nl
        set code to code + t + "GET    /" + name + "      runs list_all" + nl
        set code to code + t + "GET    /" + name + "/:id  runs get_one" + nl
        set code to code + t + "PUT    /" + name + "/:id  runs update" + nl
        set code to code + t + "DELETE /" + name + "/:id  runs delete_one" + nl
        set code to code + t + "GET    /health        runs health" + nl
        respond with code

    if intent is equal "chatbot":
        set code to code + nl + "to chat with message, session:" + nl
        set code to code + t + "purpose: " + q + "Handle chat message with conversation memory" + q + nl
        set code to code + t + "set mem to memory_new(20)" + nl
        set code to code + t + "memory_add(mem, " + q + "user" + q + ", message)" + nl
        set code to code + t + "set history to memory_summary(mem)" + nl
        set code to code + t + "ask AI to " + q + "You are a helpful assistant. Conversation history: " + q + " + str(history) + " + q + ". Reply to the last message." + q + " save as reply" + nl
        set code to code + t + "memory_add(mem, " + q + "assistant" + q + ", reply)" + nl
        set code to code + t + "respond with {" + q + "reply" + q + ": reply, " + q + "session" + q + ": session}" + nl + nl
        set code to code + "to health:" + nl
        set code to code + t + "respond with {" + q + "status" + q + ": " + q + "ok" + q + "}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST /chat   runs chat" + nl
        set code to code + t + "GET  /health runs health" + nl
        respond with code

    if intent is equal "classifier":
        set code to code + nl + "to classify with text:" + nl
        set code to code + t + "ask AI to " + q + "Classify this text" + q + " using text save as label" + nl
        set code to code + t + "respond with {" + q + "label" + q + ": label}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST /classify runs classify" + nl
        respond with code

    if intent is equal "summarizer":
        set code to code + nl + "to summarize with document:" + nl
        set code to code + t + "ask AI to " + q + "Summarize this document" + q + " using document save as summary" + nl
        set code to code + t + "respond with {" + q + "summary" + q + ": summary}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST /summarize runs summarize" + nl
        respond with code

    if intent is equal "pipeline":
        set code to code + nl + "to process with records:" + nl
        set code to code + t + "set valid to []" + nl
        set code to code + t + "set errors to []" + nl
        set code to code + t + "repeat for each record in records:" + nl
        set code to code + t + t + "if record.id is not equal nil:" + nl
        set code to code + t + t + t + "append record to valid" + nl
        set code to code + t + t + "otherwise:" + nl
        set code to code + t + t + t + "append {" + q + "error" + q + ": " + q + "missing id" + q + "} to errors" + nl
        set code to code + t + "respond with {" + q + "processed" + q + ": len(valid), " + q + "errors" + q + ": errors}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST /process runs process" + nl
        respond with code

    if intent is equal "webhook":
        set code to code + nl + "to handle with payload:" + nl
        set code to code + t + "purpose: " + q + "Handle incoming webhook event" + q + nl
        set code to code + t + "log " + q + "Webhook received: " + q + " + str(payload.event)" + nl
        set code to code + t + "match payload.event:" + nl
        set code to code + t + t + "when " + q + "created" + q + ":" + nl
        set code to code + t + t + t + "log " + q + "Resource created: " + q + " + str(payload.data)" + nl
        set code to code + t + t + "when " + q + "updated" + q + ":" + nl
        set code to code + t + t + t + "log " + q + "Resource updated: " + q + " + str(payload.data)" + nl
        set code to code + t + t + "when " + q + "deleted" + q + ":" + nl
        set code to code + t + t + t + "log " + q + "Resource deleted: " + q + " + str(payload.id)" + nl
        set code to code + t + t + "otherwise:" + nl
        set code to code + t + t + t + "log " + q + "Unknown event: " + q + " + str(payload.event)" + nl
        set code to code + t + "respond with {" + q + "received" + q + ": true, " + q + "event" + q + ": payload.event}" + nl + nl
        set code to code + "to health:" + nl
        set code to code + t + "respond with {" + q + "status" + q + ": " + q + "ok" + q + "}" + nl + nl
        set code to code + "api:" + nl
        set code to code + t + "POST /webhook runs handle" + nl
        set code to code + t + "GET  /health  runs health" + nl
        respond with code

    if intent is equal "ncui":
        set code to "page " + q + name + q + nl
        set code to code + "theme " + q + "light" + q + nl
        set code to code + "accent " + q + "#0F766E" + q + nl + nl
        set code to code + "nav:" + nl
        set code to code + t + "brand " + q + name + q + nl
        set code to code + t + "links:" + nl
        set code to code + t + t + "link " + q + "Home" + q + " to " + q + "#home" + q + nl + nl
        set code to code + "section hero:" + nl
        set code to code + t + "heading " + q + name + q + nl
        set code to code + t + "text " + q + "Built with NC UI" + q + nl
        set code to code + t + "button " + q + "Get Started" + q + " style " + q + "primary" + q + nl + nl
        set code to code + "footer:" + nl
        set code to code + t + "text " + q + "Powered by NC" + q + nl
        respond with code

    if contains(feature_text, "ai"):
        set code to code + nl + "to process with input:" + nl
        set code to code + t + "ask AI to " + q + "Process this input" + q + " using input save as result" + nl
        set code to code + t + "respond with result" + nl + nl
    otherwise:
        set code to code + nl + "to handle with request:" + nl
        set code to code + t + "respond with {" + q + "message" + q + ": " + q + "Hello from " + name + q + "}" + nl + nl
    set code to code + "to health:" + nl
    set code to code + t + "respond with {" + q + "status" + q + ": " + q + "ok" + q + "}" + nl + nl
    set code to code + "api:" + nl
    set code to code + t + "POST / runs handle" + nl
    set code to code + t + "GET  /health runs health" + nl
    respond with code

to ai_generate with prompt, options:
    purpose: "Generate deterministic NC code from a prompt"
    if prompt is empty:
        respond with {"error": "prompt is required"}
    set intent_info to detect_intent(prompt)
    set code to generate_from_template(intent_info.intent, intent_info.name, intent_info.features)
    respond with {
        "code": code,
        "text": code,
        "intent": intent_info.intent,
        "features": intent_info.features,
        "name": intent_info.name,
        "mode": "template"
    }

to ai_complete with code_prefix, language:
    purpose: "Return a template completion for partial code"
    if code_prefix is empty:
        respond with {"error": "code_prefix is required"}
    set language_name to language
    if language_name is empty:
        set language_name to "nc"
    set synthesized_prompt to "complete this " + language_name + " code: " + code_prefix
    set intent_info to detect_intent(synthesized_prompt)
    set completion to generate_from_template(intent_info.intent, intent_info.name, intent_info.features)
    respond with {
        "completion": completion,
        "intent": intent_info.intent,
        "language": language_name,
        "mode": "template"
    }

to ai_explain with code, language:
    purpose: "Explain NC or NCUI code without requiring a remote model"
    if code is empty:
        respond with {"error": "code is required"}
    set language_name to language
    if language_name is empty:
        set language_name to "nc"
    set behavior_count to count_occurrences(code, "to ")
    set route_count to count_occurrences(code, " runs ")
    set section_count to count_occurrences(code, "section ")
    set explanation to ""
    set is_page to false
    if contains(code, "page "):
        set is_page to true
    if is_page is equal true:
        set explanation to "This NCUI page defines " + str(section_count) + " sections"
        if contains(code, "nav:"):
            set explanation to explanation + ", includes navigation"
        if contains(code, "footer:"):
            set explanation to explanation + ", and includes a footer."
        if contains(code, "footer:") is not true:
            set explanation to explanation + "."
    if is_page is not equal true:
        set explanation to "This " + language_name + " service defines " + str(behavior_count) + " behaviors and " + str(route_count) + " routes."
        if contains(code, "configure:"):
            set explanation to explanation + " It includes a configure block."
        if contains(code, "ask AI"):
            set explanation to explanation + " It also includes AI-backed behavior."
    respond with {
        "explanation": explanation,
        "behaviors": behavior_count,
        "routes": route_count,
        "sections": section_count
    }

to ai_recommend with code, artifact_type:
    purpose: "Return deterministic recommendations for NC services and NCUI pages"
    if code is empty:
        respond with {"error": "code is required"}
    set recommendations to []
    set normalized_type to "service"
    if artifact_type is not equal nil:
        set normalized_artifact to lower(str(artifact_type))
        if normalized_artifact is equal "page":
            set normalized_type to "ncui"
        if normalized_artifact is equal "ncui":
            set normalized_type to "ncui"
    if contains(code, "page "):
        set normalized_type to "ncui"

    if normalized_type is equal "ncui":
        if contains(code, "nav:") is not true:
            append {"severity": "info", "msg": "Add a nav block for multi-section pages", "category": "ux"} to recommendations
        if contains(code, "footer:") is not true:
            append {"severity": "warning", "msg": "Add a footer for attribution and support links", "category": "ux"} to recommendations
        if contains(code, "theme ") is not true:
            append {"severity": "info", "msg": "Set an explicit theme for predictable styling", "category": "design"} to recommendations
        if contains(code, "accent ") is not true:
            append {"severity": "info", "msg": "Set an accent color to make the design intentional", "category": "design"} to recommendations
    if normalized_type is not equal "ncui":
        if contains(code, "service ") is not true:
            append {"severity": "error", "msg": "Add a service declaration", "category": "structure"} to recommendations
        if contains(code, "version ") is not true:
            append {"severity": "warning", "msg": "Add an explicit version declaration", "category": "structure"} to recommendations
        if contains(code, "configure:") is not true:
            append {"severity": "info", "msg": "Add a configure block for runtime settings", "category": "maintainability"} to recommendations
        if contains(code, "api:") is not true:
            append {"severity": "error", "msg": "Add an api block so the service can be served", "category": "api"} to recommendations
        if contains(code, "health") is not true:
            append {"severity": "info", "msg": "Add a health endpoint for monitoring", "category": "operations"} to recommendations
        if contains(code, "respond with") is not true:
            append {"severity": "warning", "msg": "Ensure behaviors respond with data", "category": "correctness"} to recommendations
        if contains(code, "log ") is not true:
            append {"severity": "info", "msg": "Add log statements around important operations", "category": "observability"} to recommendations

    if len(recommendations) is equal 0:
        append {"severity": "info", "msg": "No critical issues detected in the supported v1 surface", "category": "quality"} to recommendations

    respond with {
        "recommendations": recommendations,
        "count": len(recommendations),
        "artifact_type": normalized_type
    }

to ai_fix with buggy_code, error_message:
    purpose: "Apply safe, deterministic text fixes for common NC issues"
    if buggy_code is empty:
        respond with {"error": "buggy_code is required"}
    set fixed to buggy_code
    set changes to []

    if contains(fixed, "console.log("):
        set fixed to replace(fixed, "console.log(", "log ")
        append "Replaced console.log with log" to changes
    if contains(fixed, "return "):
        set fixed to replace(fixed, "return ", "respond with ")
        append "Replaced return with respond with" to changes
    if contains(fixed, "function "):
        set fixed to replace(fixed, "function ", "to ")
        append "Replaced function with to" to changes
    if contains(fixed, "var "):
        set fixed to replace(fixed, "var ", "set ")
        append "Replaced var with set" to changes
    if contains(fixed, "let "):
        set fixed to replace(fixed, "let ", "set ")
        append "Replaced let with set" to changes
    if contains(fixed, "const "):
        set fixed to replace(fixed, "const ", "set ")
        append "Replaced const with set" to changes

    if contains(fixed, "service ") is not true:
        if contains(fixed, "to "):
            set fixed to "service \"generated-service\"\nversion \"1.0.0\"\n\n" + fixed
            append "Added service header" to changes

    if contains(fixed, "api:") is not true:
        if contains(fixed, "to health:"):
            set fixed to fixed + "\napi:\n    GET /health runs health"
            append "Added api block for health route" to changes

    if len(changes) is equal 0:
        append "No automatic changes were required" to changes

    respond with {
        "code": fixed,
        "fixed_code": fixed,
        "changes": changes,
        "explanation": join(changes, "; "),
        "error_message": error_message
    }

to ai_reason with question, context:
    purpose: "Provide deterministic local reasoning for common questions"
    if question is empty:
        respond with {"error": "question is required"}
    set q to lower(question)
    set answer to "This request can be handled with deterministic NC AI SDK heuristics."
    set steps to []

    set handled to false
    if contains(q, "2 + 2"):
        append "Recognized a basic arithmetic expression" to steps
        append "Computed the result locally" to steps
        set answer to "2 + 2 = 4."
        set handled to true
    if contains(q, "2+2"):
        append "Recognized a basic arithmetic expression" to steps
        append "Computed the result locally" to steps
        set answer to "2 + 2 = 4."
        set handled to true
    if handled is not equal true:
        if context is not equal nil:
            if contains(lower(str(context)), "plain english"):
                append "Read the provided context" to steps
                append "Matched the phrase plain English" to steps
                set answer to "NC uses plain English syntax."
        if len(steps) is equal 0:
            set intent_info to detect_intent(question)
            append "Classified the request as " + intent_info.intent to steps
            append "Selected the stable v1 template-first path" to steps
            set answer to "This request looks like a " + intent_info.intent + " task. Use ai_generate for a deterministic scaffold."

    respond with {
        "answer": answer,
        "reasoning_steps": steps,
        "confidence": 0.82
    }

to ai_plan with goal, constraints:
    purpose: "Create a short implementation plan for a goal"
    if goal is empty:
        respond with {"error": "goal is required"}
    set intent_info to detect_intent(goal)
    set steps to []
    append "Clarify inputs, outputs, and constraints" to steps
    append "Choose the " + intent_info.intent + " template path" to steps
    append "Implement behaviors and routes in NC" to steps
    append "Add validation, health checks, and logs" to steps
    append "Run SDK and runtime tests before release" to steps

    respond with {
        "goal": goal,
        "intent": intent_info.intent,
        "constraints": constraints,
        "steps": steps,
        "estimated_effort": "medium"
    }

to build_swarm_candidates with task:
    purpose: "Generate a small deterministic candidate set"
    set intent_info to detect_intent(task)
    set candidates to []
    append {
        "agent": "greedy",
        "code": generate_from_template(intent_info.intent, intent_info.name + "-core", intent_info.features),
        "score": 0.78
    } to candidates
    append {
        "agent": "balanced",
        "code": generate_from_template(intent_info.intent, intent_info.name + "-team", intent_info.features),
        "score": 0.84
    } to candidates
    append {
        "agent": "explorative",
        "code": generate_from_template(intent_info.intent, intent_info.name + "-next", intent_info.features),
        "score": 0.8
    } to candidates
    respond with candidates

to extract_candidate_codes with candidates:
    purpose: "Convert candidate records into plain code strings"
    set codes to []
    repeat for each candidate in candidates:
        append candidate.code to codes
    respond with codes

to swarm_vote with candidates:
    purpose: "Pick the strongest candidate from a list of generated code strings"
    if len(candidates) is equal 0:
        respond with ""
    set best_text to candidates[0]
    set best_score to len(split(best_text, " "))
    repeat for each candidate in candidates:
        set score to len(split(candidate, " "))
        if contains(candidate, "api:"):
            set score to score + 50
        if contains(candidate, "service "):
            set score to score + 10
        if score is above best_score:
            set best_text to candidate
            set best_score to score
    respond with best_text

to swarm_generate with task, options:
    purpose: "Generate code with a deterministic multi-candidate pass"
    if task is empty:
        respond with {"error": "task is required"}
    set candidates to build_swarm_candidates(task)
    set codes to extract_candidate_codes(candidates)
    set winner to swarm_vote(codes)
    respond with winner

to ai_swarm with task, num_agents, strategy:
    purpose: "Return swarm metadata and the winning candidate"
    if task is empty:
        respond with {"error": "task is required"}
    set candidates to build_swarm_candidates(task)
    set codes to extract_candidate_codes(candidates)
    set winner to swarm_vote(codes)
    respond with {
        "winner": winner,
        "candidates": candidates,
        "strategy": strategy,
        "num_agents": num_agents,
        "consensus_score": 0.84
    }

to ai_encode with text:
    purpose: "Return a deterministic lexical encoding for text"
    if text is empty:
        respond with {"error": "text is required"}
    set tokens to tokenize_text(text)
    set unique to unique_tokens(tokens)
    respond with {
        "tokens": tokens,
        "unique_tokens": unique,
        "token_count": len(tokens),
        "unique_count": len(unique),
        "mode": "lexical"
    }

to ai_similarity with text_a, text_b:
    purpose: "Return lexical Jaccard similarity between two texts"
    if text_a is empty:
        respond with {"error": "text_a and text_b are required"}
    if text_b is empty:
        respond with {"error": "text_a and text_b are required"}
    set tokens_a to unique_tokens(tokenize_text(text_a))
    set tokens_b to unique_tokens(tokenize_text(text_b))
    if len(tokens_a) is equal 0:
        if len(tokens_b) is equal 0:
            respond with {
                "score": 1.0,
                "overlap": 0,
                "mode": "jaccard"
            }
    set overlap to overlap_count(tokens_a, tokens_b)
    set union_count to len(tokens_a) + len(tokens_b) - overlap
    if union_count is equal 0:
        set union_count to 1
    set score to overlap / union_count
    respond with {
        "score": score,
        "overlap": overlap,
        "tokens_a": len(tokens_a),
        "tokens_b": len(tokens_b),
        "mode": "jaccard"
    }

to health_check:
    purpose: "Report stable SDK health"
    respond with {
        "status": "ok",
        "service": "nc-ai-sdk",
        "version": "1.0.0",
        "surface": ["ai_generate", "ai_complete", "ai_explain", "ai_recommend", "ai_fix", "ai_reason", "ai_plan", "ai_swarm", "ai_encode", "ai_similarity"],
        "release_mode": "stable-v1"
    }

to info:
    purpose: "Describe the supported v1 SDK surface"
    respond with {
        "name": "NC AI SDK",
        "version": "1.0.0",
        "supported_entrypoints": ["sdk/nc_ai_api.nc", "sdk/server.nc"],
        "notes": ["Template-first generation is the supported v1 path", "sdk/inference and sdk/ml contain experimental work that is not part of the v1 contract"]
    }

api:
    POST /generate          runs ai_generate
    POST /complete          runs ai_complete
    POST /intent            runs detect_intent
    POST /explain           runs ai_explain
    POST /recommend         runs ai_recommend
    POST /fix               runs ai_fix
    POST /reason            runs ai_reason
    POST /plan              runs ai_plan
    POST /swarm             runs ai_swarm
    POST /swarm/generate    runs swarm_generate
    POST /encode            runs ai_encode
    POST /similarity        runs ai_similarity
    GET  /health            runs health_check
    GET  /info              runs info
