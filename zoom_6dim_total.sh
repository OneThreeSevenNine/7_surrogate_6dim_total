#!/usr/bin/env bash

set -Eeuo pipefail

OUTER_THRESHOLD="${OUTER_THRESHOLD:-0.001}"
MAX_OUTER_ITERATIONS="${MAX_OUTER_ITERATIONS:-50}"
PREFLIGHT_ONLY="${PREFLIGHT_ONLY:-0}"

OTW_ROOT="${OTW_ROOT:-/data/user03_ssy/OTW}"
PROJECT_DIR="${PROJECT_DIR:-${OTW_ROOT}/12_surrogate_6dim_total}"
MATLAB_DIR="${PROJECT_DIR}/0D"
SURROGATE_DIR="${PROJECT_DIR}/6D"
RBF_DIR="${PROJECT_DIR}/RBF"

CURRENT_ITERATION=0
RUN_ID=""
RUN_ROOT=""

fail() {
    trap - ERR
    echo "[ERROR] $*" >&2
    echo "[CONTEXT] outer=${CURRENT_ITERATION}" >&2
    [[ -z "${RUN_ROOT}" ]] || echo "[CONTEXT] run root: ${RUN_ROOT}" >&2
    exit 1
}

on_error() {
    local exit_code=$?
    trap - ERR
    echo "[ERROR] Unexpected failure at line ${BASH_LINENO[0]:-unknown} (exit ${exit_code})." >&2
    echo "[CONTEXT] outer=${CURRENT_ITERATION}" >&2
    [[ -z "${RUN_ROOT}" ]] || echo "[CONTEXT] run root: ${RUN_ROOT}" >&2
    exit "${exit_code}"
}
trap on_error ERR

on_signal() {
    trap - ERR INT TERM
    echo "[ERROR] Workflow interrupted by user or scheduler." >&2
    echo "[CONTEXT] outer=${CURRENT_ITERATION}" >&2
    [[ -z "${RUN_ROOT}" ]] || echo "[CONTEXT] run root: ${RUN_ROOT}" >&2
    exit 130
}
trap on_signal INT TERM

validate_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

validate_numeric_literal() {
    [[ "$1" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?$ ]]
}

matlab_path_guard() {
    local value
    for value in "$PROJECT_DIR" "$MATLAB_DIR" "$SURROGATE_DIR" "$RBF_DIR" "$RUN_ROOT"; do
        [[ "$value" != *"'"* ]] || fail "MATLAB paths must not contain a single quote: ${value}"
    done
}

run_matlab() {
    local working_dir="$1"
    local expression="$2"
    (
        cd "$working_dir"
        matlab -batch "$expression"
    )
}

read_status() {
    local status_file="$1"
    local status
    [[ -f "$status_file" ]] || fail "Status file not found: ${status_file}"
    status="$(tr -d '[:space:]' < "$status_file")"
    printf '%s\n' "$status"
}

for command_name in matlab tee date mkdir cat tr; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Required command is unavailable: ${command_name}"
done
validate_numeric_literal "$OUTER_THRESHOLD" || fail "OUTER_THRESHOLD must be a numeric literal."
validate_positive_integer "$MAX_OUTER_ITERATIONS" || fail "MAX_OUTER_ITERATIONS must be a positive integer."
[[ "$PREFLIGHT_ONLY" == "0" || "$PREFLIGHT_ONLY" == "1" ]] || fail "PREFLIGHT_ONLY must be 0 or 1."

for required_dir in "$PROJECT_DIR" "$MATLAB_DIR" "$SURROGATE_DIR" "$RBF_DIR"; do
    [[ -d "$required_dir" ]] || fail "Required directory not found: ${required_dir}"
done
[[ -w "$MATLAB_DIR" ]] || fail "0D directory is not writable: ${MATLAB_DIR}"
[[ -w "$SURROGATE_DIR" ]] || fail "6D directory is not writable: ${SURROGATE_DIR}"

for required_file in \
    "$MATLAB_DIR/A_main_0D.m" \
    "$MATLAB_DIR/update_scale_factor_matched.m" \
    "$MATLAB_DIR/write_outer_target.m" \
    "$MATLAB_DIR/save_converged_outer_to_zoom.m" \
    "$SURROGATE_DIR/surrogate6_config.m" \
    "$SURROGATE_DIR/surrogate6_main.m" \
    "$SURROGATE_DIR/surrogate6_solve_root.m" \
    "$SURROGATE_DIR/evaluate_outer_convergence.m" \
    "$RBF_DIR/model/rbf6_model.mat" \
    "$RBF_DIR/surrogate6_predict.m" \
    "$RBF_DIR/rbf6_predict.m" \
    "$RBF_DIR/rbf6_kernel.m" \
    "$RBF_DIR/rbf6_label.m" \
    "$RBF_DIR/rbf6_hash.m"; do
    [[ -f "$required_file" ]] || fail "Required file not found: ${required_file}"
done

matlab_path_guard
run_matlab "$SURROGATE_DIR" \
    "addpath('$SURROGATE_DIR'); addpath('$RBF_DIR'); threshold=str2double('$OUTER_THRESHOLD'); assert(isfinite(threshold) && threshold>0); config=surrogate6_config(); assert(license('test','Statistics_Toolbox')); loaded=load(config.model_file,'model'); model=loaded.model; assert(model.version==3 && model.data_schema_version==2); assert(isequal(model.input_names,config.input_order)); assert(isequal(model.output_names,config.output_order)); [y,j,info]=surrogate6_predict(model,model.rbf.X); usable=info.is_usable & info.in_training_range & info.in_training_hull; assert(any(usable)); assert(size(y,2)==6 && size(j,2)==6 && size(j,3)==3); assert(all(all(isfinite(y(usable,:)))));"
echo "[OK] Preflight checks passed."

if [[ "$PREFLIGHT_ONLY" == "1" ]]; then
    echo "[OK] PREFLIGHT_ONLY=1; no 0D or surrogate coupling iteration was started."
    exit 0
fi

RUN_ID="run_$(date '+%Y%m%d_%H%M%S')_$$"
RUN_ROOT="${SURROGATE_DIR}/runs/${RUN_ID}"
mkdir -p "$RUN_ROOT"
matlab_path_guard
LOG_FILE="${RUN_ROOT}/workflow.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo "    0D + stable-classifier + six-output RBF coupling"
echo "    Project: ${PROJECT_DIR}"
echo "    Run root: ${RUN_ROOT}"
echo "    Outer relative tolerance: ${OUTER_THRESHOLD}"
echo "    Maximum outer iterations: ${MAX_OUTER_ITERATIONS}"
echo "============================================================"

CONVERGED=0
for ((n=1; n<=MAX_OUTER_ITERATIONS; n++)); do
    CURRENT_ITERATION="$n"
    OUTER_DIR="${RUN_ROOT}/$(printf 'outer_%03d' "$n")"
    TARGET_FILE="${OUTER_DIR}/outer_target.csv"
    MATCHED_FILE="${OUTER_DIR}/matched_result.csv"
    SURROGATE_STATUS_FILE="${OUTER_DIR}/surrogate_status.txt"
    OUTER_STATUS_FILE="${OUTER_DIR}/outer_status.txt"
    RESIDUAL_FILE="${OUTER_DIR}/outer_residual.csv"

    echo
    echo "############################################################"
    echo "Starting outer iteration ${n}/${MAX_OUTER_ITERATIONS}"
    echo "############################################################"

    echo "[STEP 1] Running the seven-variable 0D calculation."
    if ! run_matlab "$MATLAB_DIR" \
        "n=${n}; coupling_root='$RUN_ROOT'; A_main_0D;"; then
        fail "MATLAB 0D calculation failed during outer iteration ${n}."
    fi
    [[ -f "$TARGET_FILE" ]] || fail "0D calculation did not create ${TARGET_FILE}."

    echo "[STEP 2] Solving the stable two-pressure RBF inverse problem."
    if ! run_matlab "$SURROGATE_DIR" \
        "addpath('$SURROGATE_DIR'); addpath('$RBF_DIR'); surrogate6_main(${n},'$RUN_ROOT');"; then
        [[ ! -f "${OUTER_DIR}/surrogate_diagnostic.txt" ]] || cat "${OUTER_DIR}/surrogate_diagnostic.txt" >&2
        fail "SVM/RBF prediction failed during outer iteration ${n}."
    fi
    SURROGATE_STATUS="$(read_status "$SURROGATE_STATUS_FILE")"
    [[ "$SURROGATE_STATUS" == "CONVERGED" ]] || fail "Unexpected surrogate status: ${SURROGATE_STATUS}"
    [[ -f "$MATCHED_FILE" ]] || fail "Surrogate calculation did not create ${MATCHED_FILE}."

    echo "[STEP 3] Evaluating bypass/core flow and efficiency residuals."
    if ! run_matlab "$SURROGATE_DIR" \
        "addpath('$SURROGATE_DIR'); evaluate_outer_convergence(${n},'$RUN_ROOT',str2double('$OUTER_THRESHOLD'));"; then
        fail "Unable to calculate outer residuals for iteration ${n}."
    fi
    [[ -f "$RESIDUAL_FILE" ]] || fail "Residual calculation did not create ${RESIDUAL_FILE}."
    OUTER_STATUS="$(read_status "$OUTER_STATUS_FILE")"

    if [[ "$OUTER_STATUS" == "CONVERGED" ]]; then
        echo "[STEP 4] Saving the final converged surrogate result to the zoom history."
        if ! run_matlab "$MATLAB_DIR" \
            "save_converged_outer_to_zoom(0,0,${n},'$RUN_ROOT');"; then
            fail "Unable to save the final converged result for outer iteration ${n}."
        fi
        CONVERGED=1
        echo "[OK] All four outer residuals are below ${OUTER_THRESHOLD}; converged at outer iteration ${n}."
        break
    fi
    [[ "$OUTER_STATUS" == "NOT_CONVERGED" ]] || fail "Unexpected outer status: ${OUTER_STATUS}"
    echo "[OUTER] Not converged; applying the RBF/0D and RBF-0D map corrections in the next iteration."
done

if ((CONVERGED == 0)); then
    fail "The workflow did not converge within ${MAX_OUTER_ITERATIONS} outer iterations."
fi

echo "============================================================"
echo "    Fast surrogate coupling completed successfully"
echo "    Results: ${RUN_ROOT}"
echo "============================================================"