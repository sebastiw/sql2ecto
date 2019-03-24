# This will not create the whole migration file, just the stuff that
# goes into the change() function.
#
# Run it:
# $ mysqldump --no-data > dumped-table-structures.sql
# $ sed -n -f mysql-to-elixir.sed dumped-table-structures.sql

# Everything inside create table statement
/^CREATE TABLE `.*` (/,/^) ENGINE=/{
    s/CREATE TABLE `\(.*\)`.*/    create table(:\1) do/p

    /^\s*`.*`.*/{
        h
        x

        # column name
        s/^\s*`\(.*\)` .*$/      add :\1/p
        x
        h
        # Consume
        s/^\s*`.*` \(.*\)$/\1/

        # Column type
        {
            # Booleans first
            s/tinyint(1).*/, :boolean/p

            h
            x

            # Only type, nothing more
            s/^\([a-z]\+\).*$/\1/

            # Integers
            s/\(tiny\|small\|big\)\?int/, :integer/p

            # Floats
            s/float/, :float/p

            # Strings
            s/\(var\)\?char/, :string/p
            s/\(tiny\|medium\|long\)\?text/, :string/p

            # Binaries
            s/\(long\)\?blob/, :binary/p

            # Dates/times
            s/\(timestamp\|datetime\)/, :utc_datetime/p
            s/^date$/, :date/p

            x
        }
        # Consume
        s/^[a-z]\+\s*\(.*\)$/\1/
        h
        x

        # Size of type
        s/^(\([0-9]\+\)).*$/, size: \1/p
        s/^(\([0-9]\+\),\([0-9]\+\)).*$/, precision: \1, scale: \2/p
        x
        h

        # Consume
        s/^([0-9,]\+)\s\+\(.*\)$/\1/
        s/^unsigned\s\(.*\)/\1/
        s/^COLLATE\s[^ ]\+\s\(.*\)/\1/


        # NULL
        /^\NOT NULL.*$/{
            h

            s/^NOT NULL.*/, null: false/p
            x

            # Consume
            s/^NOT NULL\s*\(.*\)$/\1/
        }

        # DEFAULT
        /^DEFAULT .*$/{
            h

            s/^DEFAULT \('[^']*'\|NULL\).*$/, default: \1/p
            x
            h
            # Consume
            s/^DEFAULT \('[^']*'\|NULL\)[ ,]*\(.*\)$/\2/
        }

        # COMMENT
        s/^COMMENT '\([^']*\)'.*$/, comment: "\1"/p
        # Consume
        s/^COMMENT '[^']*'[ ,]\(.*\)$/\1/

        # Print rest of it for Debugging
        p
    }

    s/^).*/    end\n/p

}
