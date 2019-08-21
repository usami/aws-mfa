set fail 1

function aws-mfa -d "authenticate aws cli access with mfa token"
    set -l mfa_device_file $__fish_config_dir/mfadevice

    if test ! -e "$mfa_device_file"
        command touch $mfa_device_file
        _ask_device_arn > $mfa_device_file
        echo "Created MFA device file $mfa_device_file" | command sed "s|$HOME|~|" >&2
    end

    set -l mfa_device (command head -n 1 $mfa_device_file)

    set -l json (command aws sts get-session-token --serial-number $mfa_device --token-code (_ask_token))
    if test $status -eq 0
        set -gx AWS_ACCESS_KEY_ID     (echo $json | command jq -r '.Credentials.AccessKeyId')
        set -gx AWS_SECRET_ACCESS_KEY (echo $json | command jq -r '.Credentials.SecretAccessKey')
        set -gx AWS_SESSION_TOKEN     (echo $json | command jq -r '.Credentials.SessionToken')
        echo 'Authentication Success!'
    else
        return $fail
    end
end

function _ask_device_arn
    while true
        read -l -P 'Please enter your MFA device ARN: ' arn

        if test -n $arn
            echo $arn
            return
        end
    end
end

function _ask_token
    while true
        read -l -P 'Please enter your MFA token: ' token

        if test -n $token
            echo $token
            return
        end
    end
end
