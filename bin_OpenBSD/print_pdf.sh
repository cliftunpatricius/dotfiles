#!/bin/sh

pdf_file="${1}"
readonly pdf_file

ps_file="${pdf_file%.pdf}.ps"
readonly ps_file

if test ! -f "${ps_file}"
then
	pdf2ps "${pdf_file}" "${ps_file}"
fi

lpr "${ps_file}"
