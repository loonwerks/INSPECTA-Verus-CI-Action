#!/bin/bash -l

echo "sourcepath: $1"
echo "environment-variables: $2"
echo "outputfile: $3"

startTimeStamp=$(date)

rustup toolchain list
rustup target list | grep \(installed\)
rustup component list | grep \(installed\)

sourcePath=system/hamr/microkit
if [[ -n $1 ]]; then
	sourcePath=$1
fi

if [[ -n $2 ]]; then
	for kv in $(echo $2 | jq -r 'to_entries | .[] | .key + "=" + (.value | @sh)'); do
		echo "setting ${kv}"
		export $kv;
	done
fi

outputFile='verus-report.json'
if [[ -n $3 ]]; then
	outputFile=$3
fi

echo "{ }" >> "${outputFile}"
ACCUM_EXIT_CODE=0
for makefile in $(find $GITHUB_WORKSPACE/${sourcePath}/crates -name Makefile -exec grep -H verus-json: \{\} \; | cut --delimiter=: -f 1); do
	echo "found makefile ${makefile}"
	componentDir=$(dirname ${makefile})
	componentName=$(basename ${componentDir})
	runCommand=(make -C ${componentDir} verus-json)
	echo "run command: ${runCommand[@]}" 
	"${runCommand[@]}"
	EXIT_CODE=$?
	if [ "XX ${EXIT_CODE}" != "XX 0" ]; then
		ACCUM_EXIT_CODE=${EXIT_CODE}
	fi
	tmpFile=$(mktemp)
	accumTmpFile=$(mktemp)
	jq "{\"${componentName}\" : .}" ${componentDir}/verus_results.json > "${tmpFile}" \
		&& jq -s 'add' ${outputFile} ${tmpFile} > "${accumTmpFile}" \
		&& mv ${accumTmpFile} ${outputFile} &&  rm ${tmpFile}
done

accumTmpFile=$(mktemp)
jq '{"component-verifications" : .}' ${outputFile} > "${accumTmpFile}" \
	&& mv "${accumTmpFile}" "${outputFile}"

accumTmpFile=$(mktemp)
cat ${outputFile} | jq --arg timestamp "${startTimeStamp}" \
    --arg exitcode ${ACCUM_EXIT_CODE} \
    '. += $ARGS.named' > "${accumTmpFile}" \
	&& mv "${accumTmpFile}" "${outputFile}"

echo "timestamp=$(date)" >> $GITHUB_OUTPUT
echo "status=${ACCUM_EXIT_CODE}" >> $GITHUB_OUTPUT

echo "exit code: ${ACCUM_EXIT_CODE}"
if [ "XX ${ACCUM_EXIT_CODE}" = "XX 0" ]; then
	exit 0
else
	exit 1
fi
