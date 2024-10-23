# script
search_and_parse() {
    local input_dir="$1"
    local output_dir="$2"
    local parser="../src/parser -input"
    mkdir -p "$output_dir${input_dir#$1}"

    for item in "$input_dir"/*; do
        if [ -f "$item" ] && [ "${item##*.}" = "py" ]; then
            echo
            echo "Testing $item"
	        output_file="$2/$(basename "$item")"
            output_file="${output_file%.py}.out"
            $parser "$item" "-output" "$output_file"
            dot -Tpdf "$output_file" -o "${output_file%.out}.pdf"
            output_file="${output_file%.out}.pdf"
            echo "Made $output_file"
            echo
        fi
    done
}

cd ../src
make
search_and_parse "../tests" "../out"
make clean