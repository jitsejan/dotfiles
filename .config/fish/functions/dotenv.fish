function dotenv
    set file ".env"

    if test (count $argv) -gt 0
        set file $argv[1]
    end

    if not test -f $file
        echo "dotenv: $file not found"
        return 1
    end

    for line in (grep -v '^\s*#' $file | grep -v '^\s*$')
        set key (string split -m1 '=' $line)[1]
        set value (string split -m1 '=' $line)[2]

        # trim quotes
        set value (string trim -c '"' $value)
        set value (string trim -c "'" $value)

        set -gx $key $value
    end
end
