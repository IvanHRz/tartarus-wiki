# Graph Report - /tmp/gx-tartarus  (2026-07-10)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3248 nodes · 4930 edges · 232 communities (186 shown, 46 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 693 edges (avg confidence: 0.76)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107
- Community 108
- Community 109
- Community 110
- Community 111
- Community 112
- Community 113
- Community 114
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Community 120
- Community 121
- Community 122
- Community 123
- Community 124
- Community 125
- Community 126
- Community 127
- Community 128
- Community 129
- Community 130
- Community 131
- Community 132
- Community 133
- Community 134
- Community 135
- Community 136
- Community 137
- Community 138
- Community 139
- Community 140
- Community 141
- Community 142
- Community 143
- Community 144
- Community 145
- Community 146
- Community 147
- Community 148
- Community 149
- Community 150
- Community 151
- Community 152
- Community 153
- Community 154
- Community 155
- Community 156
- Community 157
- Community 158
- Community 159
- Community 160
- Community 161
- Community 162
- Community 163
- Community 164
- Community 165
- Community 166
- Community 167
- Community 168
- Community 169
- Community 170
- Community 171
- Community 172
- Community 173
- Community 174
- Community 175
- Community 176
- Community 177
- Community 178
- Community 179
- Community 180
- Community 181
- Community 182
- Community 183
- Community 184
- Community 185
- Community 186
- Community 187
- Community 188
- Community 189
- Community 190
- Community 191
- Community 192
- Community 193
- Community 194
- Community 195
- Community 196
- Community 197
- Community 198
- Community 199
- Community 200
- Community 201
- Community 202
- Community 203
- Community 204
- Community 205
- Community 206
- Community 207
- Community 208
- Community 209
- Community 210
- Community 211
- Community 212
- Community 213
- Community 214
- Community 215
- Community 216
- Community 217
- Community 218
- Community 219
- Community 220
- Community 221
- Community 222
- Community 223
- Community 224
- Community 225
- Community 226
- Community 227

## God Nodes (most connected - your core abstractions)
1. `calculate_risk()` - 67 edges
2. `HmacVerifier` - 50 edges
3. `NeuralGraph` - 39 edges
4. `EngagementReportModel` - 34 edges
5. `_evt()` - 33 edges
6. `_parse_event()` - 30 edges
7. `_generate_engagement_report_impl()` - 30 edges
8. `_safe_eval_condition()` - 28 edges
9. `TestSigmaSafeEval` - 26 edges
10. `SigmaRule` - 22 edges

## Surprising Connections (you probably didn't know these)
- `test_is_valid_rejects_missing_or_malformed_header()` --calls--> `HmacVerifier`  [INFERRED]
  /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/tests/unit/test_hmac_verifier.py → /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/security/hmac_verifier.py
- `test_related_no_pool()` --calls--> `get_related()`  [INFERRED]
  /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/tests/test_alert_ux_router.py → /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/alert_ux_router.py
- `test_is_ignored_no_redis()` --calls--> `is_ignored()`  [INFERRED]
  /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/tests/test_alert_ux_router.py → /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/alert_ux_router.py
- `analyze_single_event()` --calls--> `analyze_event()`  [INFERRED]
  /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/analyzer_router.py → /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/llm_analyzer.py
- `_generate_engagement_report_impl()` --calls--> `match_attack_chains()`  [INFERRED]
  /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/report_router.py → /sessions/optimistic-gifted-dijkstra/mnt/Documents/Tartarus/engine/engine/attack_chains.py

## Import Cycles
- None detected.

## Communities (232 total, 46 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (79): ArgumentParser, BehaviorConfig, ConfigError, EngineConfig, _expand_env_vars(), GhostIP, load_config(), LoggingConfig (+71 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (60): _check_scope(), clear_memo(), _decode(), get_memo(), get_related(), ignore_ip(), is_ignored(), list_ignored() (+52 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (43): _escape(), generate_html_report(), generate_pdf(), TARTARUS — PDF Forensic Report Generator (Phase 7).  Generates PDF reports from, Render forensic report HTML from event/trace data.      Uses inline HTML (no Jin, HTML-escape a string., Generate PDF report bytes., Generate standalone HTML report string. (+35 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (32): ai_status(), analyze_batch(), analyze_session(), analyze_session_by_ip(), analyze_single_event(), analyzer_stats(), BatchRequest, _format_event_for_prompt() (+24 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (37): KillChainTracer, datetime, TARTARUS — Kill Chain Tracer (Phase 12).  Correlates multi-source attacks from t, Classify kill chain stage based on the highest-order protocol seen., Weighted average confidence across seen protocol sources., Insert kill chain trace into PostgreSQL, return trace ID., Track multi-source attack patterns per IP using Redis windows., Record an event and check if it triggers a kill chain trace.          Returns th (+29 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (43): Tests for OpenCanary webhook flow — logtype mapping, normalization, risk., Source IP extracted from body.src_host fallback., Missing source IP defaults to 0.0.0.0., Username from logdata appended to command string., LOGTYPE_MAP has no duplicate logtype keys (catches SNMP/NTP bug)., SSH protocol gets Credential Access., SMB gets Lateral Movement., RDP gets Lateral Movement. (+35 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (41): analyze_and_update(), _analyze_claude(), _analyze_deepseek(), analyze_event(), _analyze_kimi(), _build_event_prompt(), _rate_limit_ok(), TARTARUS — Multi-LLM Event Analyzer (Phase 4).  Fallback cascade: Claude Sonnet (+33 more)

### Community 7 - "Community 7"
Cohesion: 0.10
Nodes (16): calculate_risk(), Calculate risk score (0-100) and MITRE ATT&CK mapping for an event.      Returns, _evt(), Comprehensive tests for TARTARUS Risk Engine — all 11 protocols + attack pattern, Create minimal event dict for risk engine testing., TestCanaryProtocol, TestFTPProtocol, TestHTTPProtocol (+8 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (41): attack_http(), attack_mcp(), attack_prometheus(), attack_ssh(), attack_tcp(), attack_telnet(), bulk_insert(), _event() (+33 more)

### Community 9 - "Community 9"
Cohesion: 0.10
Nodes (3): NeuralGraph, protocolColors, riskColor()

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (38): _docx_document_rels_xml(), _docx_document_xml(), make_docx(), make_pdf(), make_xlsx(), _pdf_escape(), TARTARUS — Canary document generator (Thinkst-style web-bug docs).  Pure, stdlib, Build word/_rels/document.xml.rels — the external image relationship.      This (+30 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (33): Any, AsyncClient, IcmpCanary — HTTP webhook event publisher.  Posts TARTARUS-schema event dicts to, GET ``<base_url>/health`` — returns True on 200, False otherwise., Close the HTTP client. Idempotent., Posts JSON events to the TARTARUS engine webhook with HMAC auth.      Args:, HMAC-SHA256 hex digest of ``body`` with the shared key., Post one event to the webhook. Retries on 5xx/timeouts.          Raises on perma (+25 more)

### Community 12 - "Community 12"
Cohesion: 0.05
Nodes (38): autoCheck, badge, btnNext, btnPrev, btnRefresh, btnScan, credCombos, credCount (+30 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (25): find_repo_root(), mock_pg_pool(), mock_redis(), _MockAcquire, _MockConnection, _MockPool, Path, pytest_configure() (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.07
Nodes (37): _make_notifier(), Tests for Notifier alert dispatch — decision logic, rate limiting, formatting., Risk exactly at threshold triggers alert., First alert from IP is not rate-limited., Repeat alert from same IP within 5min is rate-limited., Without Redis, rate limiting is disabled., Create a Notifier with mock Redis and configurable threshold., Returns True when at least one channel enabled. (+29 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (35): bucket_interval_to_pg(), compute_adaptive_bucket_interval(), compute_trend(), format_bucket_label(), datetime, timedelta, TARTARUS — Adaptive histogram bucketing helpers.  Shared by both the live app hi, Return optimal bucket size based on engagement duration.      Guarantees between (+27 more)

### Community 16 - "Community 16"
Cohesion: 0.06
Nodes (36): _parse_event(), Parse Beelzebub JSON into a dict ready for PostgreSQL insertion., Parse an HTTP honeypot event., Event without source IP is skipped., ISO 8601 timestamp parsed correctly., Payload JSONB preserves the full raw event., HTTP fields present but Protocol says SSH → override to HTTP., dest_port extracted from ServerAddr field. (+28 more)

### Community 17 - "Community 17"
Cohesion: 0.06
Nodes (35): Phase 1 — Consumer and events API tests., Parse a TCP honeypot event with HTTP-like Body → TCP/HTTP., C2: main.py must stay under 600 lines., C1: No pandas in engine code., All service example YAMLs are valid., Example configs must NOT contain real API keys., BUG-036 regression: repo_root resolves regardless of CWD., SSH login attempt gets baseline risk + MITRE mapping. (+27 more)

### Community 18 - "Community 18"
Cohesion: 0.09
Nodes (32): build_attack_story(), _build_timeline_chart(), dispatch_stats(), dispatch_to_thehive(), DispatchRequest, _fetch_core_data(), _fetch_event(), _fetch_events_for_trace() (+24 more)

### Community 19 - "Community 19"
Cohesion: 0.09
Nodes (30): Event, _classify_status(), _probe_tcp(), datetime, TARTARUS — sensor health worker (Sprint 2 / BUG-022).  Background asyncio task t, Execute one health-check pass over every row in sensor_registry.      Returns th, Run health-check passes forever (or until *stop_event* is set).      The loop ne, Schedule run_loop as a background task and return it.      The engine startup ho (+22 more)

### Community 20 - "Community 20"
Cohesion: 0.08
Nodes (30): bootstrap_known_sensors(), get_infra_topology(), get_sensors_status(), HeartbeatRequest, _json_safe(), post_heartbeat(), BaseModel, Request (+22 more)

### Community 21 - "Community 21"
Cohesion: 0.11
Nodes (26): check_threshold(), _fingerprint(), make_fingerprint(), TARTARUS — Session scoring in Redis with TTL decay + IP:UserAgent fingerprint., Public helper to compute the fingerprint (matches ``score_event`` key)., Build a stable fingerprint grouping an attacker by ip + client.      Uses ``sha1, Map a numeric risk score to a severity bucket.      >=85 critical, >=70 high, >=, Accumulate the score for an attacker fingerprint and refresh its TTL.      - fin (+18 more)

### Community 22 - "Community 22"
Cohesion: 0.10
Nodes (28): events_histogram(), events_stats(), get_attack_map(), get_attack_summary(), get_credentials(), get_events(), get_events_geo(), get_hash_intel() (+20 more)

### Community 23 - "Community 23"
Cohesion: 0.11
Nodes (25): compute_icmp_canary_score(), _distinct_targets_within_window(), _prune(), IcmpCanary sensor scoring — sliding-window aggregate by source IP.  Ghost IPs sh, Drop entries older than the sweep window from ``_hits[src]``., Count distinct target IPs from ``src`` in the last window., Return the risk score (int, 0..100) for one IcmpCanary event.      Side effect:, Clear all per-source state. Used by tests to isolate runs. (+17 more)

### Community 24 - "Community 24"
Cohesion: 0.13
Nodes (25): _check_hypotheses_have_conclusions(), _check_internal_links(), _check_iocs_have_context(), _check_no_empty_sections(), _check_no_english_leaks(), _check_no_placeholder_data(), _check_no_simulation(), _check_recommendations_present() (+17 more)

### Community 25 - "Community 25"
Cohesion: 0.13
Nodes (26): Redis, _cache_get(), _cache_set(), enrich_hash(), enrich_ip(), _enrich_no_cache(), _is_private(), _query_circl() (+18 more)

### Community 26 - "Community 26"
Cohesion: 0.14
Nodes (26): _b64url_decode(), _b64url_encode(), _create_token(), ensure_users_table(), _extract_token(), get_me(), _get_pool(), _get_redis() (+18 more)

### Community 27 - "Community 27"
Cohesion: 0.13
Nodes (4): Evaluate a Sigma ``condition`` string against block results.      Accepts the bo, _safe_eval_condition(), Security tests for the Sigma condition evaluator (BUG-015).  These tests pin the, TestSigmaSafeEval

### Community 28 - "Community 28"
Cohesion: 0.16
Nodes (24): applyScenarioPreset(), bindStepEvents(), _buildDeployPayload(), closeWizard(), getOS(), getProfile(), handleAddCanary(), handleAddCred() (+16 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (24): build_attack_map(), honeypot_label(), protocol_to_category(), Map a raw protocol to a friendly event category (fallback: as-is)., high if avg >= 70, medium if >= 40, low otherwise., Sensor id = COALESCE(honeypot_id, protocol), lowercased, no whitespace., Human label for a sensor: friendly protocol name + ' Honeypot'., windows if protocol is RDP/SMB or id contains 'win', else linux. (+16 more)

### Community 30 - "Community 30"
Cohesion: 0.13
Nodes (24): _build_csv(), _build_xlsx(), export_events(), export_normalized(), _fmt(), TARTARUS — Event Export Router (CSV, XLSX)., Export events in normalized Chronos-DFIR format., Export honeypot events as CSV or XLSX. (+16 more)

### Community 31 - "Community 31"
Cohesion: 0.08
Nodes (25): Tests for Canarytoken webhook flow — normalization, risk, notification., calculate_risk returns 4-tuple including factors list., src_ip key extracts correctly., SourceIP key extracts correctly., Missing IP defaults to 0.0.0.0., token_type and type keys both resolve., memo and description keys both resolve., CANARY protocol events score >= 40. (+17 more)

### Community 32 - "Community 32"
Cohesion: 0.11
Nodes (25): _build_app(), dev_client(), enforcing_client(), mock_pool(), Integration tests for the IcmpCanary webhook endpoint (router + HMAC + model)., Test client with dev-mode bypass (no signing required)., When HMAC enforcement is on, missing header → 401., Valid HMAC + valid single event → 202 with accepted=1. (+17 more)

### Community 33 - "Community 33"
Cohesion: 0.10
Nodes (25): _mock_ws(), Phase 4 — WebSocket manager + endpoint tests., broadcast() returns immediately when no clients are connected., broadcast_event() sends the correct JSON shape., broadcast_event() truncates commands longer than 200 chars., Create a mock WebSocket that records sent messages., broadcast_event() handles events with minimal data without raising., engine/main.py imports ws_manager correctly. (+17 more)

### Community 34 - "Community 34"
Cohesion: 0.10
Nodes (24): _fetch(), Verify that the running UI (localhost:8888 via nginx) serves JS/HTML that contai, <select id='filterProtocol'> contains an ICMP option., graph.js protocol→edge color mapping has an icmp entry., timeline.js PROTO_COLORS and PROTO_KEYS include icmp., Stylesheet has .proto-icmp badge class (cyan)., Best-effort GET. Returns None if the UI is down (so tests skip)., The wizard source advertises the ICMP Canary sensor in its catalog. (+16 more)

### Community 35 - "Community 35"
Cohesion: 0.11
Nodes (23): is_ssrf_safe(), Validate URL is not targeting internal/private networks., Phase 5 — Website Cloner unit tests., Templates directory exists with JSON files., cloner_router module is importable., RFC1918 addresses are blocked., localhost and 127.x.x.x are blocked., 169.254.x.x (link-local) is blocked. (+15 more)

### Community 36 - "Community 36"
Cohesion: 0.11
Nodes (23): download_compose(), Download raw docker-compose.yml for a template., generate_sensor_compose(), Generate a docker-compose.yml for a remote sensor deployment., Phase 6 — Deployer unit tests., deploy_router module is importable., Three deployment templates available., Full sensor compose has both services. (+15 more)

### Community 37 - "Community 37"
Cohesion: 0.10
Nodes (23): detection_evidence(), detection_stats(), detections_by_rule(), detections_by_technique(), evaluate_events(), list_detections(), list_loaded_rules(), TARTARUS — Detection Router.  Endpoints for Sigma-based detection results stored (+15 more)

### Community 38 - "Community 38"
Cohesion: 0.12
Nodes (22): export_stix(), Export IOCs as a STIX 2.1 bundle of Indicator SDOs., extract_iocs(), _filter_truthy(), _iso(), TARTARUS IOC Extractor — Extract and deduplicate IOCs from PostgreSQL events., Format a datetime (or None) as ISO-8601, returning None for falsy values.      a, Drop None/empty entries from a list-or-None field. Defensive against     asyncpg (+14 more)

### Community 39 - "Community 39"
Cohesion: 0.12
Nodes (23): correlate_sessions(), Group events into attack sessions by source IP + temporal window.      Args:, correlate_around_detections(), Build micro-chains around Sigma detections.      Creates temporal windows around, _make_mock_pool(), Tests for TARTARUS Smart Correlator + Session Correlator.  Uses asyncpg mock poo, Create a mock asyncpg pool with configurable query results., No detections -> empty result. (+15 more)

### Community 40 - "Community 40"
Cohesion: 0.14
Nodes (18): count_attackers(), Count distinct attacker source IPs within the unified time window.      Uses the, _make_app(), Unified attacker-window contract.  The dashboard shows the attacker count in sev, hours=0 (all-time) and hours=24 must issue different SQL., Same endpoint, different windows, must issue different SQL., Both routes must return the same shape (delegation, no duplication)., _RecordingConn (+10 more)

### Community 41 - "Community 41"
Cohesion: 0.14
Nodes (22): build_stix_bundle(), _escape(), hash_to_pattern(), _indicator(), ip_to_pattern(), _now_stix(), TARTARUS — STIX 2.1 Exporter (hand-serialized, no stix2 dependency).  Pure funct, Current UTC timestamp in STIX format, e.g. '2026-07-09T00:00:00.000Z'. (+14 more)

### Community 42 - "Community 42"
Cohesion: 0.08
Nodes (23): Phase 10 — OpenCanary webhook normalization tests., LOGTYPE_MAP has entries for FTP, SMB, MySQL, RDP., FTP logtype 5000 maps correctly., SMB logtype 8001 maps correctly., MySQL logtype 12001 maps correctly., RDP logtype 14001 maps correctly., SMB protocol gets Lateral Movement mapping., FTP protocol gets Credential Access mapping. (+15 more)

### Community 43 - "Community 43"
Cohesion: 0.15
Nodes (21): generate_decoy_usage_rule(), Path, TARTARUS — Decoy Usage (reuse) detection (Mahoraga idea).  Today TARTARUS detect, Serialize a rule dict to a YAML string, safely escaping the secret., Generate and persist a decoy-reuse Sigma rule for ``secret``.      Writes ``deco, Stable short hash of the secret — used for filenames and rule id.      NEVER exp, Build a Sigma honeypot rule matching the exact reuse of a decoy secret.      The, # NOTE: secret_value is passed as a Python str data value — NOT (+13 more)

### Community 44 - "Community 44"
Cohesion: 0.12
Nodes (21): Build a verifier from process environment.          Production (``TARTARUS_ENV=p, BUG-016 — unit tests for HmacVerifier.  Pure tests of the verifier's signing + c, No secret + production env → fail-fast at startup., v0.7.0 BUG-HMAC-fallback: only TARTARUS_ICMP_HMAC_KEY set in     production must, v0.7.0 BUG-HMAC-fallback: when both vars are set, the legacy var     is ignored, v0.7.0 BUG-HMAC-fallback: legacy var alone in dev mode must NOT     promote the, If the client signs body A but sends body B, the digest must not match., A valid signature under a different secret must not pass. (+13 more)

### Community 45 - "Community 45"
Cohesion: 0.16
Nodes (7): EngagementReportModel, BaseModel, Unified schema for engagement report data.      VRA = Verificable, Repetible, Au, Model should ignore extra fields (ConfigDict extra=ignore)., Tests for the Pydantic report model., Model with zero data should produce valid HTML context., TestEngagementReportModel

### Community 46 - "Community 46"
Cohesion: 0.14
Nodes (18): mint_document_token(), Mint a document canary token and return ``(token_value, file_bytes)``.      Shar, Return a normalized safe relative path, or ``None`` if unsafe.      Rejects: emp, _sanitize_path(), _FailingLLM, _FakePool, T6-5 — industry-profile deception filetree generator tests., Minimal asyncpg-pool stand-in: ``async with pool.acquire() as conn``. (+10 more)

### Community 47 - "Community 47"
Cohesion: 0.10
Nodes (19): app(), mock_pool(), plant_dir(), F-302 regression — POST /deploy/execute end-to-end contract.  Locks in the respo, Selected sensors map to TCP probes; with no real backend the probes     fail and, A non-skip scan profile without scan_target reports a failure entry,     instead, status=complete when every component succeeded., The planter falls back to a generic .txt recipe so the deploy never     fails ju (+11 more)

### Community 48 - "Community 48"
Cohesion: 0.14
Nodes (15): BeelzebubClient, build_enrichment_prompt(), _classify_credential_type(), _empty_response(), TARTARUS — Beelzebub AI Client (Agents 26-29).  Sanitises engagement data and se, Fallback when AI is unavailable or fails., Build the AI prompt from sanitised data., AI enrichment client for TARTARUS reports.      Reads provider config from envir (+7 more)

### Community 49 - "Community 49"
Cohesion: 0.21
Nodes (19): _fail(), http_get(), http_post(), insert_event(), _jitter(), main(), main_async(), _ok() (+11 more)

### Community 50 - "Community 50"
Cohesion: 0.14
Nodes (18): build_icmp_event(), Any, datetime, IcmpCanary — event builder.  Normalizes an observed ICMP packet into the TARTARU, Return ISO 8601 UTC timestamp with millisecond precision (Z suffix).      Exampl, Build a TARTARUS ICMP event dict from captured packet data.      Args:         s, _utc_iso8601_ms(), Tests for sensors/icmp_canary/event_builder.py. (+10 more)

### Community 51 - "Community 51"
Cohesion: 0.16
Nodes (18): _cleanStep(), _computeBarColors(), _formatBucketLabel(), initTimeline(), loadTimeline(), meanLinePlugin, PROTO_COLORS, PROTO_KEYS (+10 more)

### Community 52 - "Community 52"
Cohesion: 0.14
Nodes (17): build_mitre_evidence_map(), match_attack_chains(), _match_template(), normalize_tactic(), TARTARUS — Attack Chain Templates & MITRE Evidence Mapping.  Honeypot-specific a, Match chain templates against observed tactics per IP.      Queries events withi, Match a single IP's observed tactics against a chain template., Build a technique-to-evidence map from events and detections.      Returns: {tec (+9 more)

### Community 53 - "Community 53"
Cohesion: 0.11
Nodes (10): Unknown protocol should still get deception baseline., Empty command should not crash., None command should not crash., Score should never exceed 100 even with multiple triggers., Multiple attack patterns should accumulate but cap at 100., Each risk factor must have factor, points, description keys., Payload as JSON string should be parsed correctly., Event without protocol should not crash. (+2 more)

### Community 54 - "Community 54"
Cohesion: 0.14
Nodes (17): _canary_base_url(), CanaryDocumentCreate, CanaryTokenCreate, create_canary_document(), create_canary_token(), delete_canary_token(), ExternalTokenRegister, list_canary_tokens() (+9 more)

### Community 55 - "Community 55"
Cohesion: 0.14
Nodes (6): MetricsCollector, Any, TARTARUS — In-memory metrics collector and /metrics endpoint., Lightweight in-memory metrics — no external dependencies., Test metrics collector., TestMetrics

### Community 56 - "Community 56"
Cohesion: 0.20
Nodes (6): Notifier, Evaluate and send alert. Returns True if alert was sent., Send a test message on a specific channel., Store last 50 alerts in Redis list., Return last 50 notification entries., Multi-channel alert dispatcher with Redis rate-limiting.

### Community 57 - "Community 57"
Cohesion: 0.14
Nodes (9): Any, A single parsed Sigma rule with evaluation logic., Evaluate event against this rule. Returns hit dict or None., Evaluate a single detection block (AND of all field conditions)., Parse 'field|modifier1|modifier2' into (field, [modifiers])., Case-insensitive field lookup in event dict., Return a match function based on modifiers., Evaluate the condition string against block results.          Uses :func:`_safe_ (+1 more)

### Community 58 - "Community 58"
Cohesion: 0.15
Nodes (11): get_yara_engine(), load_yara(), Path, TARTARUS — YARA rule engine for payload/command scanning., Total .yar and .yara files across all subdirectories., Load YARA rules into the module-level singleton., Scan text against loaded YARA rules (module-level convenience)., Compiles and runs YARA rules against text payloads. (+3 more)

### Community 59 - "Community 59"
Cohesion: 0.12
Nodes (17): _find_repo_root(), Path, Sprint 2 Prompt 3 — tests for scripts/validate_docs.py.  The script is plain std, quiet=True returns empty string when no drift; full report otherwise., BUG-035 regression: script path must resolve regardless of CWD., collect_metrics + evaluate must produce a non-empty report., Inject a fake metric value far outside its tolerance and confirm     the evaluat, --json mode must emit parseable JSON. (+9 more)

### Community 61 - "Community 61"
Cohesion: 0.20
Nodes (18): $(), escapeHtml(), _humanAgo(), loadCanaryTokens(), loadCredentials(), loadDeploymentStatus(), loadDetections(), loadHoneyCredentials() (+10 more)

### Community 62 - "Community 62"
Cohesion: 0.15
Nodes (10): Packet, IcmpListener, IcmpCanary — ICMP echo-request listener.  Sniffs ICMP traffic (scapy), applies w, Stop the sniffer (idempotent)., Process one captured packet. Returns the event dict or None.          This is th, Run all filters; build + optionally reply; return event or None., Construct an ICMP echo reply (type 0) for ``in_pkt``., Hand the event off to the publisher (or injected dispatcher). (+2 more)

### Community 63 - "Community 63"
Cohesion: 0.15
Nodes (12): _get_client_ip(), BaseHTTPMiddleware, Request, RequestResponseEndpoint, Response, rate_limit(), RateLimitMiddleware, TARTARUS — Redis-based sliding window rate limiter + ASGI middleware. (+4 more)

### Community 64 - "Community 64"
Cohesion: 0.15
Nodes (11): _merge_windows(), datetime, TARTARUS — Smart Correlation Engine.  Detection-centered correlation: creates te, Merge overlapping temporal windows. Input must be sorted by start., Test temporal window merging., Non-overlapping windows remain separate., Overlapping windows merge into one., Adjacent (touching) windows merge. (+3 more)

### Community 65 - "Community 65"
Cohesion: 0.23
Nodes (16): _make_app(), _payload(), BUG-016 — HMAC verification on POST /webhooks/opencanary.  Six test cases per Sp, Signature computed under a different secret → 401., Sign body A, send body B → mismatch caught, 401., In dev mode, request without header passes but logs a warning., Mount the opencanary router with a stubbed pool + injected verifier., Correct signature → 200 with the normal accepted response. (+8 more)

### Community 66 - "Community 66"
Cohesion: 0.30
Nodes (16): attack_http(), attack_https(), attack_mcp(), attack_prometheus(), attack_ssh(), attack_tcp(), attack_telnet(), fail() (+8 more)

### Community 67 - "Community 67"
Cohesion: 0.19
Nodes (9): EngagementMemory, Any, Path, TARTARUS — Engagement Memory (Agent-05).  JSON-based persistence of engagement s, Read / write engagement summaries as JSON files., Persist an engagement summary to disk., Load a single engagement summary (or None)., Return the *limit* most-recent engagement summaries (newest first). (+1 more)

### Community 68 - "Community 68"
Cohesion: 0.13
Nodes (15): create_honey_credential(), delete_honey_credential(), honey_credentials_stats(), HoneyCredCreate, list_honey_credentials(), BaseModel, TARTARUS — Honey Credentials CRUD router (Phase 11)., List all planted honey credentials. (+7 more)

### Community 69 - "Community 69"
Cohesion: 0.20
Nodes (15): build_narrative(), Build structured narrative timeline from event patterns.      Returns list of se, _make_pool(), Tests for Narrative Builder module., Every segment has the required keys., Create a mock asyncpg pool that returns sequential fetch results., Empty database returns empty segments., Session start segments generated from first IP appearances. (+7 more)

### Community 70 - "Community 70"
Cohesion: 0.20
Nodes (5): generate_recommendations(), TARTARUS — Prioritized Recommendations Engine.  Generates P1-P5 recommendations, Generate prioritized recommendations (P1-P5) from engagement data.      Returns, Tests for the prioritized recommendations generator., TestRecommendationsEngine

### Community 71 - "Community 71"
Cohesion: 0.12
Nodes (11): HmacVerifier, Request, Return the canonical ``sha256=<hex>`` header value for *body*.          Tests us, Pure check: does *signature_header* match HMAC(secret, body)?          Always us, FastAPI-friendly verifier: read body once, validate, return bytes.          Crit, Verifies the X-Tartarus-Hmac header against the request body.      Construction, True iff this verifier is the dev-mode accept-all instance., POST /canary-tokens (CRUD) is NOT a webhook and must continue to work     withou (+3 more)

### Community 72 - "Community 72"
Cohesion: 0.17
Nodes (10): _classify_pattern(), Classify an activity cluster pattern for honeypot traffic., No dominant pattern -> mixed_activity., Empty counts -> mixed_activity., Test pattern classification logic., High SSH ratio without dangerous commands -> brute_force., High SSH ratio with dangerous commands -> execution_burst., Many distinct ports -> recon_sweep. (+2 more)

### Community 73 - "Community 73"
Cohesion: 0.17
Nodes (10): Calculate Shannon entropy from a frequency dict., _shannon_entropy(), Test Shannon entropy calculation., Single element -> entropy 0., Two equal elements -> entropy 1.0., Four equal elements -> entropy 2.0., Empty dict -> entropy 0., Highly skewed -> low entropy. (+2 more)

### Community 74 - "Community 74"
Cohesion: 0.12
Nodes (15): Phase 9 — Canarytoken webhook normalization, risk scoring, CRUD models., CANARY protocol gets score ≥40 + Discovery tactic., Canary webhook body normalizes to TARTARUS event format., Webhook normalizes both Canarytokens.org and custom key formats., Webhook with minimal body still produces valid event., Same canary payload → same SHA256., canary_router module is importable., CanaryTokenCreate model validates fields. (+7 more)

### Community 75 - "Community 75"
Cohesion: 0.12
Nodes (15): Phase 4B — Flow Classifier unit tests., 22 features matching NIDS research., All feature names are unique., Taxonomy maps all expected attack types., Each attack type maps to tactic + technique., brute_force maps to T1110., High HTTP ratio + dangerous commands → web_attack., Importance dict contains feature names with values. (+7 more)

### Community 76 - "Community 76"
Cohesion: 0.19
Nodes (14): CompletedProcess, Path, CLI smoke tests for sensors/icmp_canary/icmp_canary.py.  All tests spawn the scr, `--version` prints 'tartarus-icmp-canary 0.1.0' and exits 0., `--help` lists every flag and exits 0., `--dry-run` with a valid config prints a summary and exits 0., A non-existent config file produces exit code 2 with a stderr message., A malformed config (bad TTL, 300) produces exit code 2. (+6 more)

### Community 77 - "Community 77"
Cohesion: 0.17
Nodes (14): get_clusters(), get_micro_chains(), get_sessions(), get_summary(), Request, TARTARUS — Correlation API Router.  Provides endpoints for smart correlation: se, Attack sessions grouped by source IP with temporal windowing.      Delegates to, Detect dense activity clusters with pattern classification. (+6 more)

### Community 78 - "Community 78"
Cohesion: 0.13
Nodes (12): FlowClassifier, Random Forest flow classifier with heuristic fallback., Load pre-trained Random Forest model from disk., Map attack classification to MITRE ATT&CK., Unknown attack type returns Unknown., Zero features → benign classification., High SSH ratio + brute force score → brute_force., High port scan score → recon. (+4 more)

### Community 79 - "Community 79"
Cohesion: 0.20
Nodes (14): AISettingsRequest, configure_ai(), configure_beelzebub_ai(), get_ai_settings(), BaseModel, Request, TARTARUS — AI Settings Router., Update or add a key=value in the .env file. (+6 more)

### Community 80 - "Community 80"
Cohesion: 0.22
Nodes (9): AttackerProfile, TARTARUS — VRA (Vulnerability Risk Assessment) Correlator.  Combines events, kil, Build VRA profiles for top attackers in the given window., Compute composite VRA score (0-100)., Generate prioritized response recommendations., vra_assessment(), get_vra_assessment(), TARTARUS — VRA Assessment Router. (+1 more)

### Community 81 - "Community 81"
Cohesion: 0.19
Nodes (14): _conf(), _load_compose(), BUG-037 regression — RabbitMQ heartbeat=0 fix for silent AMQP disconnect.  Verif, Config must set heartbeat=0 (disabled) to prevent BUG-037., consumer_timeout must remain at upstream default (1800000ms / 30min).      Opera, docker-compose.yml must mount the conf file into the broker container., No env-based override of consumer_timeout in compose., The conf file must explain the tradeoff so future maintainers     don't quietly (+6 more)

### Community 82 - "Community 82"
Cohesion: 0.24
Nodes (14): collect_metrics(), _count_bugs(), _count_files(), _count_lines(), _count_protocols(), evaluate(), _grep_count(), main() (+6 more)

### Community 83 - "Community 83"
Cohesion: 0.24
Nodes (4): InfraMap, PROTO_COLORS, _relAgo(), STATUS_COLOR

### Community 84 - "Community 84"
Cohesion: 0.18
Nodes (13): canary_webbug(), canarytoken_webhook(), Request, Public web-bug receiver — hit when a canary document is OPENED.      No auth and, Receive a Canarytoken webhook and normalize to TARTARUS event.      BUG-016: HMA, broadcast(), broadcast_event(), Any (+5 more)

### Community 85 - "Community 85"
Cohesion: 0.15
Nodes (9): HoneyCredsManager, TARTARUS — Honey Credentials Manager (Phase 11).  In-memory set of planted crede, Fast in-memory honey credential checker., Load all honey credentials from PostgreSQL into memory., Reload credentials (call after CRUD operations)., client(), FastAPI TestClient with honey_creds router., Manager starts with zero credentials. (+1 more)

### Community 86 - "Community 86"
Cohesion: 0.15
Nodes (11): get_metrics(), lifespan(), BaseModel, TARTARUS Engine — Phase 4: Neural Graph + WebSocket Real-Time., Return in-memory metrics snapshot (requests, events, system stats)., Publish a scan job to RabbitMQ for the scanner container., Get current scan status from Redis., Startup: connect pools + launch consumer. Shutdown: cancel + close. (+3 more)

### Community 87 - "Community 87"
Cohesion: 0.29
Nodes (13): _bucket_row(), _make_app(), datetime, BUG-019 — Activity Timeline buckets must reflect the requested window.  The hist, mean must be computed over the FULL grid (zero buckets included),     not just t, 1-hour / 12-bucket request must produce 13 rows (inclusive of     endpoints from, Mount events_router with a mock pool that returns the provided rows.      The ro, Even when only a few buckets have events, the response must     contain the requ (+5 more)

### Community 88 - "Community 88"
Cohesion: 0.21
Nodes (13): _make_app(), POST /sensors/heartbeat endpoint contract.  Originally added in Sprint 2 Prompt, port and protocol are nullable per the model defaults., A DB failure during UPSERT should produce a 500, not crash the     application o, Sprint 2 Prompt 2: with the real verifier in place, parse errors are     handled, In dev mode the verifier accepts unsigned requests with a warning.      This rep, The handler must run a single UPSERT INSERT ... ON CONFLICT statement     with t, test_heartbeat_accepts_minimum_payload() (+5 more)

### Community 89 - "Community 89"
Cohesion: 0.19
Nodes (11): _Clock, Tests for sensors/icmp_canary/rate_limiter.py., Mutable monotonic clock for tests. Usage: ``clock.now = 10.0``., Up to max_events hits are accepted within the window., The (max_events + 1)-th hit inside the window is rejected., Once entries age past the window, new hits are accepted again., One saturated source does not affect another., test_allows_under_limit() (+3 more)

### Community 90 - "Community 90"
Cohesion: 0.19
Nodes (10): LogRecord, ColorFormatter, configure_logging(), JSONFormatter, log_event(), TARTARUS — Structured logging configuration., JSON structured log formatter for production., Colored formatter for development. (+2 more)

### Community 91 - "Community 91"
Cohesion: 0.22
Nodes (12): list_planted(), _plant_dir(), plant_token(), Path, TARTARUS — F-302 canary planter.  Plants real canary token files on the applianc, Write a canary file for *token_type* and return metadata.      Parameters     --, Return metadata about every file currently inside the plant dir., True if *path* exists and is non-empty (post-deploy health check). (+4 more)

### Community 92 - "Community 92"
Cohesion: 0.21
Nodes (12): download_filetree(), FiletreeRequest, generate_filetree(), _get_llm_client(), _public_view(), BaseModel, Request, TARTARUS — T6-5 deception filetree API.  Two endpoints:  * ``POST /deception/gen (+4 more)

### Community 93 - "Community 93"
Cohesion: 0.19
Nodes (12): get_hmac_verifier(), get_honey_creds_manager(), get_kill_chain_tracer(), get_pg_pool(), get_redis(), Request, TARTARUS — Shared dependencies for FastAPI APIRouters., Extract PostgreSQL connection pool from app state. (+4 more)

### Community 94 - "Community 94"
Cohesion: 0.19
Nodes (8): load_rules(), Path, Loads and manages all Sigma rules for real-time evaluation., Recursively load all .yml/.yaml files from rules directory., Evaluate an event against all loaded rules.          Returns list of hit dicts w, Return a summary of loaded rules by level., Load Sigma rules into the module-level singleton engine., SigmaEngine

### Community 95 - "Community 95"
Cohesion: 0.15
Nodes (11): mock_pool(), BUG-001 regression test — POST /canary-tokens with planted_location.  Before fix, The INSERT SQL must reference planted_location — verifies schema alignment., Without planted_location (it's optional in CanaryTokenCreate model), still works, Mock asyncpg pool with acquire() context manager — same as webhook auth tests., BUG-001: POST with planted_location must NOT raise 500., Response body contains the token id and created_at timestamp., test_insert_sql_includes_planted_location_column() (+3 more)

### Community 96 - "Community 96"
Cohesion: 0.24
Nodes (12): _make_app(), BUG-020 — /detections/by-rule aggregated endpoint contract.  The dashboard's DET, The ORDER BY should put critical above high above medium so the     dashboard's, Mock the shape of the SELECT in detections_by_rule()., BUG-020 core assertion: each rule card must carry a non-zero     event_count whe, Edge case: no rule has fired in the window. The response must     still be the d, The dashboard parses last_triggered with new Date(); ISO strings     only (not r, _row() (+4 more)

### Community 97 - "Community 97"
Cohesion: 0.35
Nodes (12): _make_app(), _payload(), BUG-016 — HMAC enforcement on POST /sensors/heartbeat.  Sprint 2 Prompt 1 left a, Sprint 2 Prompt 1 left a TODO(BUG-016 ...) comment; the placeholder     function, _sign(), test_body_tampering_detected(), test_dev_mode_bypass_with_warning(), test_invalid_format_rejected() (+4 more)

### Community 98 - "Community 98"
Cohesion: 0.21
Nodes (12): _load_compose(), BUG-031 regression — scanner must use Docker service names, not localhost., Scanner must NOT use network_mode: host (breaks Docker DNS)., Scanner must be on the tartarus network for service name resolution., Scanner env vars must not hardcode 127.0.0.1 or localhost., Scanner must depend on redis (it connects at startup)., scanner/main.py defaults must use Docker service names, not localhost., test_scanner_depends_on_redis() (+4 more)

### Community 99 - "Community 99"
Cohesion: 0.21
Nodes (10): _Clock, Tests for sensors/icmp_canary/deduper.py., A never-seen key is not a duplicate on first insertion., Re-inserting the same key within the TTL is a duplicate., Once a key's age exceeds the TTL, it is not a duplicate anymore., Distinct keys do not interfere with each other's dedupe state., test_after_ttl_expires_not_duplicate(), test_different_keys_independent() (+2 more)

### Community 100 - "Community 100"
Cohesion: 0.19
Nodes (11): _batchDOMUpdate(), checkHealth(), loadAttackSummary(), loadStats(), _safeUpdate(), emit(), getState(), _listeners (+3 more)

### Community 101 - "Community 101"
Cohesion: 0.20
Nodes (11): clone_website(), _extract_title(), _generate_beelzebub_yaml(), TARTARUS — Website Cloner & Identity Generator (Phase 5).  Clones websites via h, Extract <title> from HTML., Generate Beelzebub HTTP honeypot YAML config., Clone a website and rewrite forms to capture credentials.      Returns dict with, Missing title returns default. (+3 more)

### Community 102 - "Community 102"
Cohesion: 0.24
Nodes (11): clone_db(), clone_ssh(), clone_web(), CloneDBRequest, CloneSSHRequest, CloneWebRequest, BaseModel, TARTARUS — Website Cloner API router (Phase 5). (+3 more)

### Community 103 - "Community 103"
Cohesion: 0.23
Nodes (11): CanaryPlant, deploy_status(), DeployExecuteRequest, DeployRequest, generate_deployment(), HoneyCredPlant, BaseModel, TARTARUS — Sensor Deployment API router (Phase 6).  F-302 (Sprint 1, Etapa 1, Bl (+3 more)

### Community 104 - "Community 104"
Cohesion: 0.21
Nodes (7): IcmpCanaryEvent, Single ICMP echo-request event from the IcmpCanary sensor., opencanary_webhook(), Request, TARTARUS — OpenCanary webhook receiver (Phase 10).  Normalizes OpenCanary JSON l, Receive an OpenCanary JSON log event and normalize to TARTARUS event.      BUG-0, ValueError

### Community 105 - "Community 105"
Cohesion: 0.29
Nodes (11): get_config(), get_history(), _get_notifier(), Request, TARTARUS — Notification API Router.  Endpoints:     GET  /notifications/config, Return last 50 notification alerts., Return current notification config with passwords masked., Update notification config dynamically. (+3 more)

### Community 106 - "Community 106"
Cohesion: 0.18
Nodes (11): list_sensors(), BaseModel, TARTARUS — Distributed Sensor Management router (Phase 14).  Register, heartbeat, List all registered remote sensors with status., Register a new remote sensor node., Update sensor heartbeat timestamp., Remove a sensor registration., register_sensor() (+3 more)

### Community 107 - "Community 107"
Cohesion: 0.18
Nodes (9): _extract_function(), Path, Regression test for BUG-033 — ACTIVE SENSORS widget wire fix.  Verifies that ui/, Return the body of an `async function <name>(...) { ... }` block.      Brace-bal, sensor_registry rows expose sensor_id, not name. The render must     surface sen, sensor_registry uses status='active' for healthy sensors; the     legacy 'online, test_widget_handles_active_status_for_color(), test_widget_uses_sensor_registry_field_names() (+1 more)

### Community 108 - "Community 108"
Cohesion: 0.17
Nodes (11): mock_pool_conflict(), BUG-024 — Honey Credentials dedup regression tests.  Validates that: 1. The in-m, First POST returns the newly created ID., Second POST with same combo returns the existing ID (no error)., deploy_router.py INSERT into honey_credentials uses ON CONFLICT., Different (user, pass) combos are stored separately., Mock pool that simulates ON CONFLICT DO NOTHING (returns None on dupe)., test_create_duplicate_returns_existing_id() (+3 more)

### Community 109 - "Community 109"
Cohesion: 0.17
Nodes (7): Tests for TARTARUS security modules — auth, rate limiting, security headers., Test API authentication middleware., When TARTARUS_AUTH_ENABLED is false, require_auth is a no-op., When auth is enabled, missing credentials should raise 401., Valid API key should pass authentication., Valid Bearer token should pass authentication., TestAuthModule

### Community 110 - "Community 110"
Cohesion: 0.22
Nodes (10): AST, evaluate_batch(), evaluate_event(), _expand_quantifier(), _interpret_node(), Lightweight Sigma rule evaluator for real-time honeypot event matching.  Loads S, Evaluate a single event against loaded (or provided) rules., Evaluate multiple events against all loaded rules. Returns all hits. (+2 more)

### Community 111 - "Community 111"
Cohesion: 0.38
Nodes (4): Hypothesis, HypothesisEngine, TARTARUS — Dynamic Hypothesis Engine (Agent-04).  Generates testable investigati, Generate hypotheses from engagement metrics.

### Community 112 - "Community 112"
Cohesion: 0.20
Nodes (5): _InMemoryLimiter, Fallback in-memory rate limiter when Redis is unavailable., Test rate limiting functionality., Redis-backed limiter should call pipeline correctly., TestRateLimiter

### Community 113 - "Community 113"
Cohesion: 0.18
Nodes (6): RateLimiter, Redis-based sliding window rate limiter.      Uses sorted sets with timestamp sc, Check if a request is allowed under the rate limit.          Returns True if the, Return the number of remaining requests allowed in the current window., Reset rate limit counter for a key., Redis limiter should return False when over limit.

### Community 114 - "Community 114"
Cohesion: 0.18
Nodes (9): configure_cors(), BaseHTTPMiddleware, Request, RequestResponseEndpoint, Response, TARTARUS — Security package.  Originally a single module ``engine/engine/securit, Add standard security headers to every response., Apply CORSMiddleware with environment-aware origins.      - Dev (default): allow (+1 more)

### Community 115 - "Community 115"
Cohesion: 0.29
Nodes (4): _classify_kill_chain(), Classify attack session into kill chain stage., Test kill chain stage classification., TestClassifyKillChain

### Community 116 - "Community 116"
Cohesion: 0.20
Nodes (11): client_count(), connect(), disconnect(), WebSocket, Accept and register a new WebSocket client., Remove a WebSocket client from the registry., Return the number of currently connected WebSocket clients., WebSocket (+3 more)

### Community 117 - "Community 117"
Cohesion: 0.31
Nodes (10): extract_model_fields(), extract_router_context_extras(), extract_template_vars(), extract_to_html_context_extras(), main(), Path, Extract extra keys added in to_html_context() method., Extract extra context keys added in report_router.py after to_html_context(). (+2 more)

### Community 118 - "Community 118"
Cohesion: 0.45
Nodes (10): _make_app(), _payload(), BUG-016 — HMAC verification on POST /webhooks/canarytoken.  Mirrors the opencana, _sign(), test_body_tampering_detected(), test_dev_mode_bypass_with_warning(), test_invalid_format_rejected(), test_missing_header_rejected() (+2 more)

### Community 119 - "Community 119"
Cohesion: 0.31
Nodes (10): _make_app(), BUG-022 — GET /sensors/status response shape.  Mocks the asyncpg pool to verify, No rows → total=0, every count=0, sensors=[]., asyncpg returns JSONB as a JSON string by default; the response     must surface, If a future migration introduces a status value the endpoint does     not know a, _row(), test_status_endpoint_aggregates_counts_correctly(), test_status_endpoint_decodes_metadata_jsonb_string() (+2 more)

### Community 120 - "Community 120"
Cohesion: 0.27
Nodes (10): _geo_enrich(), _make_app(), _mock_redis(), T3-6 — /events/geo bulk GeoIP aggregation endpoint.  The endpoint aggregates att, Mount events_router with a mock pool + injectable redis., Return an async enrich_ip replacement driven by a per-IP geo map., Public IP is resolved into a point; private IP (geo None) omitted., A populated Redis cache is returned verbatim without hitting the DB. (+2 more)

### Community 121 - "Community 121"
Cohesion: 0.25
Nodes (10): Tests for engine/engine/models/icmp_event.py — Pydantic v2 models., A fully-populated valid event parses without error., Malformed IPv4 in source_ip raises ValidationError., raw_hash without sha256: prefix raises ValidationError., Batch model wraps single event and accepts list form., test_batch_with_mixed_validity(), test_invalid_hash_rejected(), test_invalid_ip_rejected() (+2 more)

### Community 122 - "Community 122"
Cohesion: 0.22
Nodes (6): EventDeduper, Any, IcmpCanary — event deduplicator with LRU eviction + TTL per key.  Prevents the s, LRU cache with per-entry TTL for duplicate detection.      Args:         ttl_sec, Register ``key`` and return True if it was already seen and not expired., Number of live (non-expired) entries, after pruning.

### Community 123 - "Community 123"
Cohesion: 0.18
Nodes (6): Any, IcmpCanary — per-source sliding-window rate limiter.  Despite the class name, th, Sliding-window rate limiter keyed by source IP.      Args:         max_events: m, Register a hit for ``src`` and return True if within the limit., Number of non-expired hits currently recorded for ``src``., TokenBucketPerSource

### Community 124 - "Community 124"
Cohesion: 0.27
Nodes (10): _icmp_event(), _poll_event(), AsyncClient, E2E: IcmpCanary webhook → PostgreSQL events + risk scoring.  Posts a synthetic I, Build a minimal valid IcmpCanary webhook payload., Poll the events table until a matching row appears or timeout., POST → webhook → event row exists in DB with correct fields., The event's sha256 field follows 'sha256:' + 64 hex chars format. (+2 more)

### Community 126 - "Community 126"
Cohesion: 0.22
Nodes (9): classify_ssh_client(), consume_events(), _insert_event(), TARTARUS — RabbitMQ Consumer: Beelzebub events → PostgreSQL.  Consumes JSON even, Insert a parsed event into PostgreSQL. Returns event UUID., Main consumer loop — connects to RabbitMQ and processes events.      Runs as a b, Classify SSH client from banner string.      Returns dict with ssh_tool, is_atta, Consumer module is importable. (+1 more)

### Community 127 - "Community 127"
Cohesion: 0.20
Nodes (10): _compute_sha256(), Chain of custody: SHA256 of the raw event payload., Chain of custody: same payload → same hash., Different payloads produce different hashes., Verify our hash matches hashlib directly., Parse a standard SSH honeypot event., test_parse_ssh_event(), test_sha256_deterministic() (+2 more)

### Community 128 - "Community 128"
Cohesion: 0.29
Nodes (9): _build_prompt(), _filler_bytes(), generate_manifest(), _parse_llm_json(), TARTARUS — T6-5 industry-profile deception filetree generator.  The flagship Thi, Extract ``tree`` list from an LLM string reply, tolerating fences., Inert content for a filler entry, sourced from canary_planter._RECIPES., Generate a tokenized deception filetree manifest for *profile*.      Steps: (+1 more)

### Community 129 - "Community 129"
Cohesion: 0.20
Nodes (10): generate_deploy_script(), Generate a bash deployment script for remote sensor installation., Deploy script installs Docker if missing., Deploy script uses custom sensor name., Deploy script never mounts Docker socket (C4)., Deploy script contains target IP., test_deploy_script_contains_docker(), test_deploy_script_contains_sensor_name() (+2 more)

### Community 130 - "Community 130"
Cohesion: 0.27
Nodes (8): enrich_recommendations_with_compliance(), get_normative_context(), NormativeContext, NormativeRef, TARTARUS — NIST CSF 2.0 / ISO 27001:2022 Mapper (Agent-10).  Maps findings, hypo, Add NIST/ISO references to recommendation entries.      Matches recommendations, Full normative context for the report., Aggregate all NIST/ISO references from hypotheses and Sigma hits.      Parameter

### Community 131 - "Community 131"
Cohesion: 0.20
Nodes (5): Return dict ready for Jinja2 template rendering., Build SVG pie chart segments for severity distribution., Build horizontal bar chart data for protocol distribution., Build MITRE kill chain flow data for SVG rendering., Build SVG polyline points string for risk trend.

### Community 132 - "Community 132"
Cohesion: 0.20
Nodes (9): get_iocs(), get_narrative(), protocol_timeline(), TARTARUS — Timeline & IOC Router.  Endpoints for narrative timeline, per-protoco, Cross-protocol unified timeline with lateral movement detection., Extract deduplicated IOCs from honeypot events., Structured narrative timeline from event patterns., Detailed timeline for a single protocol with per-bucket context.      BUG-019: z (+1 more)

### Community 133 - "Community 133"
Cohesion: 0.33
Nodes (9): _make_app(), BUG-023 — /canary-tokens response must surface planted_location.  The dashboard, The dashboard escapeHtml's the value before render, but the     endpoint must no, BUG-023 core regression: planted_location must be present and     non-empty on t, BUG-023 corollary: the dashboard renders 'TRIGGERED (Nx)' from     triggered_cou, _row(), test_canary_tokens_planted_location_passes_through_special_chars(), test_canary_tokens_response_includes_planted_location() (+1 more)

### Community 134 - "Community 134"
Cohesion: 0.20
Nodes (9): Phase 11 — Honey Credentials Manager unit tests., Check on empty manager returns None., Lookup with wrong credentials returns None., Count reflects number of loaded credentials., honey_creds_router module is importable., test_honey_creds_router_importable(), test_manager_check_no_match(), test_manager_check_returns_none_when_empty() (+1 more)

### Community 135 - "Community 135"
Cohesion: 0.20
Nodes (9): Tests for Timeline & IOC router — importability and structure., narrative_builder module imports and has build_narrative., ioc_extractor module imports and has extract_iocs., Router has /timeline/narrative and /iocs/extract routes., timeline_router module imports and has router., test_ioc_extractor_importable(), test_narrative_builder_importable(), test_timeline_router_endpoints() (+1 more)

### Community 136 - "Community 136"
Cohesion: 0.27
Nodes (9): _ensure_schema(), main(), process_scan_job(), TARTARUS Scanner — Consumes scan jobs from RabbitMQ, runs nmap, persists to Post, Main loop: consume scan jobs from RabbitMQ., Add new columns if missing (migration for existing DBs)., Insert or update a host in PostgreSQL with enriched scan data., Execute a scan job and persist results. (+1 more)

### Community 137 - "Community 137"
Cohesion: 0.47
Nodes (9): build(), _bullet(), _h1(), _h2(), _h3(), _para(), Path, _set_font() (+1 more)

### Community 138 - "Community 138"
Cohesion: 0.28
Nodes (7): HTTPAuthorizationCredentials, optional_auth(), Request, TARTARUS — API Authentication middleware., FastAPI dependency — enforce authentication on sensitive endpoints.      When ``, Non-blocking auth — logs caller identity without rejecting requests., require_auth()

### Community 139 - "Community 139"
Cohesion: 0.31
Nodes (8): ndarray, collect_training_data(), _derive_label(), main(), Main training pipeline., Extract labeled flow features from PostgreSQL.      Labels are derived from risk, Derive attack label from MITRE techniques and risk score., train()

### Community 140 - "Community 140"
Cohesion: 0.22
Nodes (8): HoneyCred, O(1) lookup — returns HoneyCred if match, else None., Inserting same (user, pass) overwrites in dict — count stays 1., test_manager_dedup_by_key(), HoneyCred is frozen and hashable., Manually populate manager and verify O(1) lookup., test_honeycred_dataclass(), test_manager_manual_insert_and_check()

### Community 141 - "Community 141"
Cohesion: 0.31
Nodes (4): Strip control characters and enforce max length for search queries., sanitize_query(), Test security headers middleware., TestSecurityHeaders

### Community 142 - "Community 142"
Cohesion: 0.22
Nodes (8): attack_summary(), TARTARUS Session Correlator — Group events into attack sessions., Get attack summary for dashboard cards., Build the shared time-window WHERE clause and its query params.      Args:, time_filter(), test_time_filter_alias_qualifies_column(), test_time_filter_all_time_when_hours_non_positive(), test_time_filter_windowed()

### Community 143 - "Community 143"
Cohesion: 0.19
Nodes (4): Verify severity ordering constants., Verify dangerous command set., TestDangerousCommands, TestSeverityOrder

### Community 144 - "Community 144"
Cohesion: 0.36
Nodes (6): _fires(), _load(), Tests for the Tier-1 gap-fill honeypot Sigma rules (roadmap T1-6..T1-16).  Audit, test_rule_fires_on_positive(), test_rule_has_mitre_technique_tag(), test_rule_silent_on_negative()

### Community 145 - "Community 145"
Cohesion: 0.25
Nodes (8): clone_db_responses(), Generate realistic database honeypot responses., MySQL DB responses have banner and tables., PostgreSQL DB responses have correct banner., Unknown sector defaults to financial tables., test_db_responses_mysql(), test_db_responses_postgresql(), test_db_responses_unknown_sector()

### Community 146 - "Community 146"
Cohesion: 0.25
Nodes (8): load_template(), Load a specific industry template by ID., get_template(), Load a specific industry template., Loading a specific template returns full data., Loading nonexistent template returns None., test_load_template(), test_load_template_not_found()

### Community 147 - "Community 147"
Cohesion: 0.29
Nodes (7): analyze_credential_patterns(), analyze_credentials(), _password_strength(), TARTARUS Credential Analyzer — SSH brute-force pattern analysis., Analyze credential patterns from SSH honeypot events.      Returns top combos, c, Advanced credential pattern analysis.      Returns:     - password_strength: dis, Classify password strength as weak/medium/strong.

### Community 148 - "Community 148"
Cohesion: 0.29
Nodes (7): by_protocol(), cross_protocol(), TARTARUS — Cross-Protocol Correlation API Router.  Provides endpoints for per-pr, Map a numeric risk score to a human-readable level., Per-protocol time-series histogram.      Creates evenly-spaced time buckets over, Cross-protocol attacker correlation.      Groups events by source IP within the, _risk_level()

### Community 149 - "Community 149"
Cohesion: 0.25
Nodes (7): get_deploy_templates(), List available deployment templates., list_deploy_templates(), TARTARUS — One-Click Sensor Deployer (Phase 6).  Generates docker-compose config, List available deployment templates., list_deploy_templates returns structured data., test_list_deploy_templates()

### Community 150 - "Community 150"
Cohesion: 0.25
Nodes (7): get_trace(), list_traces(), TARTARUS — Kill Chain Traces CRUD router (Phase 12)., Mark a kill chain trace as resolved., List kill chain traces with optional filters., Get a single kill chain trace with full event IDs., resolve_trace()

### Community 151 - "Community 151"
Cohesion: 0.29
Nodes (6): IcmpBatch, IcmpEventDetails, Any, BaseModel, Pydantic v2 models for IcmpCanary webhook events.  Validates the 17-field PRD sc, Batch of ICMP events or a single event at the root level.      Accepts:       -

### Community 152 - "Community 152"
Cohesion: 0.25
Nodes (7): TARTARUS Narrative Builder — Structured narrative timeline from event patterns., Convert numeric risk score to label., _risk_label(), Risk label classification., test_risk_label(), narrative_builder exports _risk_label helper., test_narrative_builder_has_risk_label()

### Community 153 - "Community 153"
Cohesion: 0.36
Nodes (4): _adaptive_bucket_seconds(), Choose time bucket size based on analysis window., Test adaptive bucket sizing., TestAdaptiveBucketSeconds

### Community 154 - "Community 154"
Cohesion: 0.25
Nodes (7): Phase 0 — Constraint and smoke tests., C2: main.py must stay under 600 lines., C1: No pandas anywhere in engine/., Verify main.py can be parsed without syntax errors., test_main_imports(), test_main_under_600_lines(), test_no_pandas_in_engine()

### Community 155 - "Community 155"
Cohesion: 0.36
Nodes (4): phase_fail(), phase_pass(), phase_skip(), attack_verify_vra.sh script

### Community 156 - "Community 156"
Cohesion: 0.43
Nodes (7): insert_event(), _jitter(), timedelta, Insert event into PostgreSQL events table., Execute the full attack simulation., run_simulation(), _sha256()

### Community 157 - "Community 157"
Cohesion: 0.32
Nodes (7): _parse_init_sql(), _parse_sql_refs(), Schema coverage test: all SQL columns used in engine code must exist in init.sql, Parse db/init.sql → {table_name: {col1, col2, ...}}., Parse engine/*.py for INSERT INTO table (col, ...) patterns., Every column referenced in INSERT INTO must exist in init.sql CREATE TABLE., test_all_insert_columns_exist_in_init_sql()

### Community 158 - "Community 158"
Cohesion: 0.25
Nodes (8): _alertUxHtml(), escapeAttr(), _fetchIntelHtml(), _initAlertUx(), loadEvents(), renderTable(), showIntelPopover(), updatePagination()

### Community 159 - "Community 159"
Cohesion: 0.29
Nodes (6): FastAPI, TARTARUS — common HMAC-SHA256 verifier for sensor webhooks (BUG-016).  Generalis, app(), Minimal FastAPI app with the canary router mounted., The handler must pass the hours arg into the SQL so a 24h dashboard     window d, test_by_rule_query_filters_by_window()

### Community 160 - "Community 160"
Cohesion: 0.38
Nodes (6): icmpcanary_webhook(), _ingest_event(), Request, TARTARUS — IcmpCanary webhook receiver (v2, ADR-0001).  Accepts ICMP events from, Risk-score, persist, broadcast, trace, notify one validated event., Receive IcmpCanary event(s). HMAC-validated, Pydantic-checked.      Accepts sing

### Community 161 - "Community 161"
Cohesion: 0.33
Nodes (6): deploy_sensors(), _probe_tcp(), TARTARUS — F-302 sensor manager.  The Mapa Maestro Cap 10 deploy contract calls, Open a TCP connection and immediately close it. True iff the port     accepts th, Probe each sensor named in *selected_sensors* and return its status.      The co, _SensorEndpoint

### Community 162 - "Community 162"
Cohesion: 0.52
Nodes (6): _fires(), _load(), Tests for the Tier-1 P0 honeypot Sigma rules (roadmap T1-1..T1-5).  Each rule is, test_rule_fires_on_positive(), test_rule_has_mitre_technique_tag(), test_rule_silent_on_negative()

### Community 163 - "Community 163"
Cohesion: 0.29
Nodes (6): POSTGRES_DB, POSTGRES_HOST, POSTGRES_PASSWORD, POSTGRES_PORT, POSTGRES_USER, reset_and_attack.sh script

### Community 164 - "Community 164"
Cohesion: 0.33
Nodes (6): AsyncClient, E2E: Ping sweep scoring escalation via IcmpCanary webhook.  Posts 5 ICMP events, 5 distinct ghost IPs from the same source escalate risk to ≥90., All 5 events from the sweep are persisted in the events table., test_five_pings_produce_high_score(), test_sweep_events_count()

### Community 165 - "Community 165"
Cohesion: 0.40
Nodes (5): NamedTuple, fix_broken_links(), LinkReport, TARTARUS — Link Checker (Agent-07).  Post-processes rendered HTML to verify inte, Scan internal anchor links and fix broken ones.      Strategy:     1. Try CIDR-s

### Community 166 - "Community 166"
Cohesion: 0.40
Nodes (4): add_kpi_table(), add_table(), Generate TARTARUS Project Report as Word document., KPIs as a horizontal table.

### Community 167 - "Community 167"
Cohesion: 0.33
Nodes (6): clone_ssh_profile(), Generate a realistic SSH honeypot identity profile., Ubuntu SSH profile has expected fields., CentOS SSH profile has expected fields., test_ssh_profile_centos(), test_ssh_profile_ubuntu()

### Community 168 - "Community 168"
Cohesion: 0.33
Nodes (6): list_templates(), List available industry templates., get_templates(), List available industry templates., list_templates returns all industry templates., test_list_templates()

### Community 169 - "Community 169"
Cohesion: 0.33
Nodes (6): Rewrite all form actions to /tartarus/capture endpoint., _rewrite_forms(), Form actions are rewritten to /tartarus/capture., HTML without forms passes through unchanged (except no injection)., test_rewrite_forms(), test_rewrite_forms_preserves_no_form()

### Community 170 - "Community 170"
Cohesion: 0.40
Nodes (5): build_export_package(), Any, TARTARUS — Export Packager (Agent-06).  Creates a ZIP archive containing all eng, Build a ZIP with all deliverables + SHA256 manifest.      Parameters     -------, _sha256()

### Community 171 - "Community 171"
Cohesion: 0.33
Nodes (3): Classify flow features into attack type.          Returns: (attack_type, confide, Classify using trained Random Forest model., Heuristic fallback when no ML model is available.

### Community 172 - "Community 172"
Cohesion: 0.33
Nodes (5): enrich_buckets_with_sigma(), TARTARUS — Sigma Bucket Enrichment (Agent-02).  Crosses Sigma detection hits wit, Cross Sigma hits with histogram buckets IN PLACE.      Parameters     ----------, Extract tooltip-friendly summary from an enriched bucket., summarise_sigma_for_tooltip()

### Community 173 - "Community 173"
Cohesion: 0.33
Nodes (5): get_translations(), TARTARUS — Bilingual translation support for engagement reports.  Provides EN↔ES, Return the translation dictionary for the given language code.      Supported: ', Look up a translation. Returns the original text if no translation found., translate()

### Community 174 - "Community 174"
Cohesion: 0.33
Nodes (5): IcmpCanary router tests — migrated to Pydantic + HMAC architecture.  The origina, ICMP events with sensor=icmp_canary get Discovery/T1018., Router module is importable after the v2 refactor., test_icmp_risk_scoring_baseline(), test_icmpcanary_router_importable()

### Community 175 - "Community 175"
Cohesion: 0.33
Nodes (5): IcmpCanary webhook flow tests — migrated to Pydantic + HMAC architecture.  Origi, ICMP with sensor=icmp_canary produces Discovery tactic., Risk factors include the icmp_canary_hit factor., test_icmp_protocol_risk_is_discovery(), test_risk_factors_include_icmp_canary_hit()

### Community 176 - "Community 176"
Cohesion: 0.40
Nodes (5): parse_nmap_xml(), TARTARUS Scanner — nmap async wrapper with XML parsing., Run nmap scan asynchronously and return parsed hosts., Parse nmap XML output into a list of enriched host dicts., run_scan()

### Community 177 - "Community 177"
Cohesion: 0.40
Nodes (3): _load_config(), TARTARUS Notification Router — Multi-channel alert delivery.  Sends alerts via E, Build notification config from environment variables.

### Community 178 - "Community 178"
Cohesion: 0.60
Nodes (3): http(), http_data(), attack_http.sh script

### Community 179 - "Community 179"
Cohesion: 0.50
Nodes (3): extract_flow_features(), TARTARUS — Flow Classifier (Phase 4B, inspired by NIDS research).  Extracts flow, Extract 22 flow features for an IP over a time window.      Uses SQL aggregates

### Community 180 - "Community 180"
Cohesion: 0.50
Nodes (3): ensure_schema(), TARTARUS — Schema migration (auto-create tables for existing deployments)., Auto-create tables and columns added after initial deploy.

### Community 183 - "Community 183"
Cohesion: 0.50
Nodes (3): Test that all Jinja2 template variables are provided by report context., All {{ var }} in engagement_report.html must exist in the report context., test_template_vars_covered()

### Community 185 - "Community 185"
Cohesion: 0.50
Nodes (3): IcmpCanary sensor tests — scaffolding.  Real tests land in task-4 (sniffer + ded, Placeholder — confirms pytest discovery for tests/sensors/., test_placeholder()

### Community 186 - "Community 186"
Cohesion: 0.50
Nodes (4): autoScan(), loadHosts(), pollScanStatus(), startScan()

## Knowledge Gaps
- **62 isolated node(s):** `_SensorEndpoint`, `setup-rpi3.sh script`, `attack_all.sh script`, `icmp_canary_demo.sh script`, `push-to-rpi.sh script` (+57 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **46 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_generate_engagement_report_impl()` connect `Community 18` to `Community 130`, `Community 67`, `Community 165`, `Community 38`, `Community 69`, `Community 70`, `Community 39`, `Community 172`, `Community 45`, `Community 77`, `Community 111`, `Community 48`, `Community 15`, `Community 173`, `Community 52`, `Community 24`, `Community 25`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Why does `lifespan()` connect `Community 86` to `Community 3`, `Community 4`, `Community 58`, `Community 136`, `Community 20`, `Community 85`, `Community 56`, `Community 26`, `Community 126`, `Community 159`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Why does `calculate_risk()` connect `Community 7` to `Community 160`, `Community 5`, `Community 104`, `Community 74`, `Community 42`, `Community 204`, `Community 174`, `Community 175`, `Community 16`, `Community 17`, `Community 84`, `Community 53`, `Community 23`, `Community 31`?**
  _High betweenness centrality (0.083) - this node is a cross-community bridge._
- **Are the 65 inferred relationships involving `calculate_risk()` (e.g. with `canary_webbug()` and `canarytoken_webhook()`) actually correct?**
  _`calculate_risk()` has 65 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `HmacVerifier` (e.g. with `CanaryDocumentCreate` and `CanaryTokenCreate`) actually correct?**
  _`HmacVerifier` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Are the 17 inferred relationships involving `FastAPI` (e.g. with `app()` and `_make_app()`) actually correct?**
  _`FastAPI` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Are the 19 inferred relationships involving `EngagementReportModel` (e.g. with `DispatchRequest` and `_generate_engagement_report_impl()`) actually correct?**
  _`EngagementReportModel` has 19 INFERRED edges - model-reasoned connections that need verification._