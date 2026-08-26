#function make
#    set output (command make $argv)
#    if string match -rq '^\s*[{[]' "$output"
#        echo $output | fx
#    else
#        echo $output
#    end
#end
#
#
#
#this one is working
# function make
#     command make $argv | while read -l line
#         if string match -rq '\{.*\}' $line

#             echo "=====raw====="
#             echo $line
#             echo "=====raw====="

#             set json (string match -r '\{.*\}' $line)
#             set prefix (string replace -r '\{.*\}' '' $line)

#             echo ""
#             echo $prefix
#             echo $json | jq .
#         else
#             echo $line
#         end
#     end
# end
#
#
#
function make
    command make $argv | while read -l line
        if string match -rq '\{.*\}' -- $line

            echo "=====raw====="
            echo $line
            echo "=====raw====="

            set json (string match -r '\{.*\}' -- $line)
            set prefix (string replace -r '\{.*\}' '' -- $line)

            echo ""
            echo $prefix
            echo $json | jq .
        else
            echo $line
        end
    end
end