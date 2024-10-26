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
	    output_folder="${output_file%.py}"
	    mkdir "../out/$output_folder"
            output_file="${output_file%.py}.out"
            $parser "$item" "-output" "$output_file"
	    mv *.csv "../out/$output_folder"
	    mv "$output_file" "../out/$output_folder" 
            echo "Made $output_file"
            echo
        fi
    done
}

cd ../src
make clean
make
search_and_parse "../tests" "../out"
make clean
