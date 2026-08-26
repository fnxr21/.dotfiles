#function gvm
#    # Source the gvm script and then run the gvm command with arguments
#    bash -c "source $HOME/.gvm/scripts/gvm && gvm $argv"
#end

#work
#function gvm
#    bash -c "source $HOME/.gvm/scripts/gvm && gvm $argv"
#end



#function gvm
#    # Capture the output of the gvm command including environment changes
#    set -l gvm_output (bash -c "source $HOME/.gvm/scripts/gvm && gvm $argv && env")
#    
#    # Check if the command was successful
#    if test $status -eq 0
#        # Extract and set environment variables from the output
#        for line in $gvm_output
#            switch $line
#                case "GOROOT=*"
#                    set -gx GOROOT (string split "=" $line)[2]
#                case "GOPATH=*"
#                    set -gx GOPATH (string split "=" $line)[2]
#                case "GVMRAP=*"
#                    set -gx GVMRAP (string split "=" $line)[2]
#                case "PATH=*"
#                    set -gx PATH (string split "=" $line)[2]
#            end
#        end
#        
#        # Ensure the new Go binary is first in PATH
#        if set -q GOROOT
#            set -gx PATH $GOROOT/bin $PATH
#        end
#        
#        # Show current version to confirm
#        echo "Active Go version:"
#        go version
#    else
#        echo "GVM command failed"
#    end
#end
