#!/bin/sh -xe

printf "code:  $VALID_REGCODE\n\
expired_code:  $EXPIRED_REGCODE\n\
notyetactivated_code: $NOT_ACTIVATED_REGCODE
" >> ~/.regcode
