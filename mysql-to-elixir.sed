# This will not create the whole migration file, just the stuff that
# goes into the change() function.
#
# TODO: Use awk, I think it might be easier
#
# Run it:
# $ mysqldump --no-data > dumped-table-structures.sql
# $ sed -n -f mysql-to-elixir.sed dumped-table-structures.sql

# Pre and post amble
1idefmodule ZZZ.Repo.Migrations.XXX do\n  use Ecto.Migration\n\n  def change do
$a \ \ end\nend

# Old Ecto migrations
/^CREATE TABLE `schema_migrations` (/,/^) ENGINE=/d

# Everything inside create table statement
# TODO: Read all rows into pattern space first in order to act upon
# primary keys for instance
/^CREATE TABLE `.*` (/,/^) ENGINE=/{
    /CREATE TABLE `[^`]*`.*/{
        s/CREATE TABLE `\([^`]*\)`.*/    create table(:\1, primary_key: false) do/
        h
    }

    /^\s*`\([^`]*\)`.*$/{
        # column name
        s/^\s*`\([^`]*\)`/      add :\1/

        # https://dev.mysql.com/doc/refman/8.0/en/integer-types.html
        s/\s\+\(integer\|tinyint\|smallint\|mediumint\|int\|bigint\)\(([0-9]\+)\)\?/, :integer/

        # https://dev.mysql.com/doc/refman/8.0/en/fixed-point-types.html
        # TODO: Find out correct type
        s/\s\+\(dec\|fixed\|decimal\|numeric\)(\([0-9]\+\),\([0-9]\+\))/, :numeric, precision: \2, scale: \3/
        s/\s\+\(dec\|fixed\|decimal\|numeric\)(\([0-9]\+\))/, :numeric, precision: \2, scale: 0/
        s/\s\+\(dec\|fixed\|decimal\|numeric\)/, :numeric, precision: 10, scale: 0/

        # https://dev.mysql.com/doc/refman/8.0/en/floating-point-types.html
        s/\s\+\(real\|double\|float\|double precision\)(\([0-9]\+\),\([0-9]\+\))/, :numeric, precision: \2, scale: \3/
        s/\s\+\(real\|double\|float\|double precision\)(\([0-9]\+\))/, :numeric, precision: \2, scale: 0/
        s/\s\+\(real\|double\|float\|double precision\)/, :numeric, precision: 10, scale: 0/

        # https://dev.mysql.com/doc/refman/8.0/en/bit-type.html
        s/\s\+bit(\([0-9]\+\))/, :bit, size: \1/

        # https://dev.mysql.com/doc/refman/8.0/en/datetime.html
        s/\s\+\(timestamp\|datetime\)/, :utc_datetime/
        s/\s\+date/, :date/

        # https://dev.mysql.com/doc/refman/8.0/en/time.html
        s/\s\+time/, :time/

        # https://dev.mysql.com/doc/refman/8.0/en/year.html
        s/\s\+year\((4)\)\?/, :date/

        # https://dev.mysql.com/doc/refman/8.0/en/char.html
        s/\s\+\(char\|varchar\)(\([0-9]\+\))/, :string, size: \2/

        # https://dev.mysql.com/doc/refman/8.0/en/binary-varbinary.html
        s/\s\+\(binary\|varbinary\)(\([0-9]\+\))/, :bit, size: \2/

        # https://dev.mysql.com/doc/refman/8.0/en/blob.html
        s/\s\+\(tinyblob\|blob\|mediumblob\|longblob\)/, :binary/
        s/\s\+\(tinytext\|text\|mediumtext\|longtext\)/, :string/

        # https://dev.mysql.com/doc/refman/8.0/en/enum.html
        # TODO: Create new custom type enum
        s/\s\+enum(\([^)]\+\))/, :enum, values: \1/

        # https://dev.mysql.com/doc/refman/8.0/en/set.html
        # TODO: Create new custom type set
        s/\s\+set(\([^)]\+\))/, :set, values: \1/

        # https://dev.mysql.com/doc/refman/8.0/en/json.html
        s/\s\+json/, :binary/

        # NULL
        s/\s\+NOT NULL/, null: false/

        # DEFAULTS
        s/\s\+DEFAULT NULL/, default: nil/
        s/\s\+DEFAULT b\?'\([^']*\)'/, default: "\1"/
        # Cast default timestamps to Unix start time
        s/\(:utc_datetime.*default:\) "0000-00-00 00:00:00"/\1 "1971-01-01 00:00:00"/

        # TODO: https://stackoverflow.com/a/34466682
        s/\s\+DEFAULT CURRENT_TIMESTAMP//
        s/\s\+ON UPDATE CURRENT_TIMESTAMP//

        # COMMENTS
        s/\s\+COMMENT '\([^']*\)'/, comment: "\1"/

        # TODO
        s/\s\+unsigned//
        s/\s\+COLLATE\s[^ ,]\+//
        s/\s\+CHARACTER SET\s[^ ,]\+//
        s/\s\+AUTO_INCREMENT/, autogenerate: true/

        # Remove trailing commas
        s/,$//

        H
    }

    # TODO: Add primary_key: true on column instead of separate statement
    /^\s\+PRIMARY KEY ([^)]\+)/{
        # Add primary key to the top
        s/\s\+PRIMARY KEY (\([^)]\+\)),\?/add \1, primary_key: true/
        s/`\([^`]\+\)`/:\1/g
        G
        s/^\([^\n]*\)\n\(\s\+create[^\n]*\)\n.*/\2\n\1/
        x
        s/^\s\+create[^\n]*\n//

        H
    }

    /^).*/{
        s/^).*/    end\n/
        H
        x
        p
    }
}
