#!/bin/bash
#
# Calculate download traffic per day
#
# Filter by a specific repository if $REPOSITORY is defined or replaced
REPO_NAME="$REPOSITORY"

if [ -n "$REPO_NAME" ]; then
    # Escape forward slash
    REPO_NAME="${REPO_NAME/\//\\/}"

    REPO_NAME_FIELD="\"repo_name\":\"($REPO_NAME)\".*"
else
    REPO_NAME_FIELD='"repo_name":"([^"]+).*'
fi

printf -v EXTRACT_FIELDS "%s"               \
    'print if s/.*'                         \
        '"cloning":([^,]+).*'               \
        '"program":"upload-pack".*'         \
        $REPO_NAME_FIELD \
        '"uploaded_bytes":([^,]+).*'        \
        '"user_login":"([^"]+).*'           \
    '/\2\t\4\t\1\t\3/'

echo -e "repository\tuser\tcloning?\trequests\tdownload [B]"

zcat -f /var/log/github-audit.log.1* |
    perl -ne "$EXTRACT_FIELDS" |
    sort |
    perl -ne '$S{$1} += $2 and $C{$1} += 1 if (/^(.+)\t(\d+)$/);END{printf("%s\t%i\t%i\n",$_,$C{$_},$S{$_}) for ( keys %S );}' |
    sort -rn -k5,5
