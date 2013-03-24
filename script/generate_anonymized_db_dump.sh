set -e

dump_id=`date +"%Y%m%d%H%M"`
work_db_name="gamersmafia_anonymized_${dump_id}"
work_dump_file="gamersmafia-${dump_id}.c.sql"
anonymized_dump_file="gamersmafia-anonymized-${dump_id}.c.sql"

# We create a copy of the production db.
pg_dump -xO -F c gamersmafia > ${work_dump_file}
createdb ${work_db_name}
pg_restore -d ${work_db_name} -F c ${work_dump_file}
rm ${work_dump_file}

# We anonymize private user info.
psql -c "DELETE FROM autologin_keys;" ${work_db_name}
psql -c "DELETE FROM gamersmafiageist_codes;" ${work_db_name}
psql -c "DELETE FROM sent_emails;" ${work_db_name}
psql -c "DELETE FROM silenced_emails;" ${work_db_name}
psql -c "UPDATE users SET password = (SELECT password from users where login='nagato');" ${work_db_name}
psql -c "UPDATE users SET email = login || '@gamersmafia.dev'" ${work_db_name}
psql -c "UPDATE users SET validkey = NULL;" ${work_db_name}
psql -c "UPDATE messages SET title = 'Asunto anonimizado';" ${work_db_name}
psql -c "UPDATE messages SET message = 'Cuerpo del mensaje anonimizado';" ${work_db_name}
psql -c "UPDATE users SET secret = NULL;" ${work_db_name}
psql -c "UPDATE users SET ipaddr = '0.0.0.0';" ${work_db_name}
psql -c "DELETE FROM users_lastseen_ips;" ${work_db_name}
psql -c "UPDATE contents SET url = replace(url, 'gamersmafia.com', 'gamersmafia.dev');" ${work_db_name}

# We generate the final anonymized dump.
pg_dump -xO -F c ${work_db_name} > ${anonymized_dump_file}

dropdb ${work_db_name}

echo "Copia anonimizada de la bd disponible: ${anonymized_dump_file}"
echo "Instrucciones: http://wiki.gamersmafia.com/wiki/FAQ"
