
function find_intersection(){
    res=""
    for item1 in $1; do
        for item2 in $2; do
            echo "ITEM1: $item1 ITEM2: $item2" >> loglog
            if [[ $item1 = $item2 ]]; then
                res="$item1"
                break
            fi
        done
        if [[ $res != "" ]]; then
            break
        fi
    done
    echo $res 
}

function process_arg () {
    availablevalues=""
    for i in $values;do
        [[ $cur =~ $i ]] && continue 
        availablevalues="$i $availablevalues"
    done

    # Check that there is no unique prefix for all remaining options (God knows why I have to do this. Must be missing something)
    # TODO when all suboptions start with the same prefix, it is not working great
    uniqueprefix=1
    prefix=${availablevalues:0:1}
    for i in $availablevalues;do
        [[ ${i:0:1} == $prefix ]] || uniqueprefix=0
    done

    if [[  ${COMP_WORDS[COMP_CWORD-1]} == "$1" ]]; then
        # echo  "The first value is about to be entered" >> loglog
        cur=""
        COMPREPLY=( $( compgen -W "${values}" -- $cur ) ) ; return
    fi
    if [[ ${COMP_WORDS[COMP_CWORD-1]} == '='  && "$cur" != *,* ]]; then
        # echo  "A supplementary value is being entered" >> loglog
        COMPREPLY=( $( compgen -W "${values}" -- $cur ) ) ; return
    fi
    if [[ ${cur:${#cur}-1:1} == "," && $uniqueprefix == 0  ]]; then
        # echo  "A supplementary value is about to be entered and there is a no unique suffix" >> loglog
        compvalues=""
        for i in $values;do
            [[ $cur =~ $i ]] && continue 
            compvalues="$i $compvalues"
        done
        cur=""
        COMPREPLY=( $( compgen -W "${compvalues}" -- $cur ) ) ;
        return
    fi
    if [[ "$cur" =~ ","  ]] ; then 
        # echo  "A supplementary value is about to be entered and there is a unique prefix or we are in the middle of one" >> loglog
        compvalues=""
        for i in $values;do
            [[ $cur =~ $i ]] && continue 
            compvalues="$compvalues ${cur%,*},$i"
            #compvalues="$compvalues $i"
        done
        COMPREPLY=( $( compgen -W "${compvalues}" -- $cur ) ) ; 

        # This is lame, we show complete list rather than last element
        # How does pahtname completion work ? 
        return
    fi
    # echo  "Everything failed ?" >> loglog
    return 255
}

function test_arg () {
    [[ ${COMP_WORDS[COMP_CWORD]} == "=" && ${COMP_WORDS[COMP_CWORD-1]} == $1 ]] && return 0
    [[ ${COMP_WORDS[COMP_CWORD-1]} == "=" && ${COMP_WORDS[COMP_CWORD-2]} == $1 ]] && return 0
    return 255
}

_scontrol()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    local commands="abort checkpoint create completing delete hold notify pidinfo listpids ping reconfigure release requeue resume setdebug show shutdown suspend takeover uhold update version"
    local subopts=""

    local shortoptions="-a -d -h -M -o -Q -v -V --"
    local longoptions="--all --details --help --hide --cluster --oneliner --quiet --verbose --version"

    # Options
    if   [[ "${cur:0:2}" == -- ]]; then COMPREPLY=( $( compgen -W "${longoptions}"  -- $cur ) ) ; return 
    elif [[ "${cur:0:1}" == -  ]]; then COMPREPLY=( $( compgen -W "${shortoptions}" -- $cur ) ) ; return ; fi

    # Search for a command in the argument list (first occurence)
    command=$(find_intersection "${COMP_WORDS[*]}" "$commands")

    # If no command has been entered, serve the list of valid commands
    [[ $command == "" ]] && { COMPREPLY=( $( compgen -W "${commands}" -- $cur ) ) ; return ; }

    # Otherwise process command
    case $command in 
    show) #TODO
        subopts="config daemons job node partition reservation slurmd step topology hostlist hostnames"
        ;;
    shutdown)
        subopts="slurmctld controller" 
        ;;
    setdebug) 
        subopts="quiet fatal error info verbose debug debug2 debug3 debug4 debug5" 
        ;;
    notify | uhold | suspend |  release | requeue | resume | hold ) 
        subopts=$( scontrol -o show jobs | cut -d' ' -f 1 | cut -d'=' -f 2 )
        ;;
    checkpoint) 
        if [[ $prev == $command ]]; then
            subopts="disable enable able create vacate error restart"
        else
            subopts=$( scontrol -o show jobs | cut -d' ' -f 1 | cut -d'=' -f 2 )
        fi
        ;;
    delete)
        objects="PartitionName Reservation"

        # Search for the current object in the argument list
        object=$(find_intersection "${COMP_WORDS[*]}" "$objects")

        # If no objects has yet been entered in the arguments, serve the list of objects
        [[ $object == "" ]] && { COMPREPLY=( $( compgen -S "=" -W "${objects}" -- $cur ) ) ; compopt -o nospace; return ; }

        if test_arg "PartitionName" ; then values=$(scontrol show partitions | grep PartitionName | cut -c 15- | cut -f 1 -d' ' | paste -s -d ' ')      ; process_arg "PartitionName"   ; return ; fi
        if test_arg "Reservation"   ; then values=$(scontrol show reservation | grep ReservationName |  cut -c 17- | cut -f 1 -d' ' | paste -s -d ' ')  ; process_arg "Reservation"     ; return ; fi
        ;;
    update) #TODO
        objects="job step node partition reservation"

        # Search for the current object in the argument list
        object=$(find_intersection "${COMP_WORDS[*]}" "$objects")

        # If no objects has yet been entered in the arguments, serve the list of objects
        [[ $object == "" ]] && { COMPREPLY=( $( compgen -W "${objects}" -- $cur ) ) ; return ; }

        # Process object
        case $object in
        job)
            local update_job_options="Account=<account> Conn-Type=<type> Contiguous=<yes|no> Dependency=<dependency_list> EligibleTime=YYYY-MM-DD[THH:MM[:SS]] ExcNodeList=<nodes> Features=<features> Geometry=<geo> Gres=<list> JobID=<id> Licenses=<name> MinCPUsNode=<count> MinMemoryCPU=<megabytes> MinTmpDiskNode=<megabytes> Name=<name> Nice[=delta] Nodelist=<nodes> NumCPUs=<min_count[-max_count] NumNodes=<min_count[-max_count] NumTasks=<count> Partition=<name> Priority=<number> QOS=<name> ReqCores=<count> ReqThreads=<count> Requeue=<0|1> ReservationName=<name> Rotate=<yes|no> Shared=<yes|no> StartTime=YYYY-MM-DD[THH:MM[:SS]] TimeLimit=[days-]hours:minutes:seconds WCKey=<key>"
            remainingoptions=""
            for i in $create_reservation_options; do
                [[ "${COMP_WORDS[@]}" =~ ${i%%=*} ]] && continue 
                remainingoptions="$i $remainingoptions"
            done
            # If a new named argument is about to be entered, serve the list of options
            [[ $cur == "" && $prev != "=" ]] && { COMPREPLY=( $( compgen -W "${create_partition_options}" -- $cur ) ) ; return ; }
            # Test all potential arguments and server corresponding values
            if test_arg "Accounts" ; then values=$(sacctmgr -pn list accounts | cut -d'|' -f1 | paste -s -d' ')                                         ; process_arg "Accounts" ; return ; fi
            if test_arg "Conn-Type"  ; then values="MESH TORUS NAV"            ; process_arg "AllocNodes"  ; return ; fi
            if test_arg "ExcNodeList"    ; then values=$(scontrol show nodes | grep NodeName | cut -c 10- | cut -f 1 -d' ' | paste -s -d ' ')                 ; process_arg "Nodes"    ; return ; fi
            if test_arg "Alternate"   ; then values=$(scontrol show partitions | grep PartitionName | cut -c 15- | cut -f 1 -d' ' | paste -s -d ' ')  ; process_arg "Alternate"   ; return ; fi
            if test_arg "NodeList="       ; then values=$(scontrol show nodes | grep NodeName | cut -c 10- | cut -f 1 -d' ' | paste -s -d ' ')            ; process_arg "Nodes"       ; return ; fi
            if test_arg "Features" ; then values=$(scontrol -o show nodes | cut -d' ' -f7 | sed 's/Features=//'  | sort -u | tr -d '()' | paste -d, -s) ; process_arg "Features" ; return ; fi
            if test_arg "Gres" ; then values=$(scontrol show config | grep GresTypes | cut -d= -f2) ; process_arg "Gres" ; return ; fi
            if test_arg "JobID" ; then values=$( scontrol -o show jobs | cut -d' ' -f 1 | cut -d'=' -f 2 ) ; process_arg "JobID" ; return ; fi
            if test_arg "Licences" ; then values=$(scontrol show config| grep Licenses | sed 's/Licenses *=//'| paste -s -d' ')                         ; process_arg "Licences" ; return ; fi
            if test_arg "Name" ; then values=$(scontrol show -o jobs | cut -d' ' -f 2 | sed 's/Name=//')                         ; process_arg "Name" ; return ; fi
            if test_arg "Partition"   ; then values=$(scontrol show partitions | grep PartitionName | cut -c 15- | cut -f 1 -d' ' | paste -s -d ' ')  ; process_arg "Partition"   ; return ; fi
            #if test_arg "QOS"   ; then values=$()  ; process_arg "QOS"   ; return ; fi
            if test_arg "ReservationName" ; then values=$(scontrol show reservation | grep ReservationName | cut -c 17- | cut -f 1 -d' ' | paste -s -d ' ') ; process_arg "ReservationName"  ; return ; fi
            #if test_arg "WCKey"   ; then values=$()  ; process_arg "WCKey"   ; return ; fi
            # If all the above did not match, a named argument has been partially entered; serve the list of arguments with no example values and do not append a trailing space
            COMPREPLY=( $( compgen -W "$(sed 's/\=[^ ]*/\=/g' <<< $create_partition_options)" -- $cur ) ) ; compopt -o nospace; return
            ;;
        step)  #TODO
            subopts=""
            ;;
        node)  #TODO
            subopts=""
            ;;
        partition)  #TODO
            subopts=""
            ;;
        reservation)  #TODO
            ;;
            esac
            ;;
    create)
        objects="partition reservation"

        # Search for the current object in the argument list
        object=$(find_intersection "${COMP_WORDS[*]}" "$objects")

        # If no objects has yet been entered in the arguments, serve the list of objects
        [[ $object == "" ]] && { COMPREPLY=( $( compgen -W "${objects}" -- $cur ) ) ; return ; }

        # Process object
        case $object in
        partition)
            # TODO set env variable with most used ones to display those only, as an option ?
            # TODO preserve order and prevent complete from using the alphabetical order ?
            local create_partition_options="PartitionName=<name> Nodes=<node_list> Alternate=<partition_name> Default=yes|no DefaultTime=days-hours:minutes:seconds|UNLIMITED DisableRootJobs=yes|no Hidden=yes|no MaxNodes=<count> MaxTime=days-hours:minutes:seconds|UNLIMITED MinNodes=<count> AllocNodes=<node_list>  PreemptMode=OFF|CANCEL|CHECKPOINT|REQUEUE|SUSPEND Priority=COUNT RootOnly=yes|no Shared=YES|NO|EXCLUSIVE|FORCE State=UP|DOWN|DRAIN|INACTIVE AllowGroups=<name>" 
            remainingoptions=""
            for i in $create_reservation_options; do
                [[ "${COMP_WORDS[@]}" =~ ${i%%=*} ]] && continue 
                remainingoptions="$i $remainingoptions"
            done
            # If a new named argument is about to be entered, serve the list of options
            [[ $cur == "" && $prev != "=" ]] && { COMPREPLY=( $( compgen -W "${create_partition_options}" -- $cur ) ) ; return ; }
            # Test all potential arguments and server corresponding values
            if test_arg "AllocNodes"  ; then values=$(scontrol show nodes | grep NodeName | cut -c 10- | cut -f 1 -d' ' | paste -s -d ' ')            ; process_arg "AllocNodes"  ; return ; fi
            if test_arg "Alternate"   ; then values=$(scontrol show partitions | grep PartitionName | cut -c 15- | cut -f 1 -d' ' | paste -s -d ' ')  ; process_arg "Alternate"   ; return ; fi
            if test_arg "Nodes"       ; then values=$(scontrol show nodes | grep NodeName | cut -c 10- | cut -f 1 -d' ' | paste -s -d ' ')            ; process_arg "Nodes"       ; return ; fi
            if test_arg "PreemptMode" ; then values="OFF CANCEL CHECKPOINT REQUEUE SUSPEND"                                                           ; process_arg "PreemptMode" ; return ; fi
            if test_arg "Shared"      ; then values="YES NO EXCLUSIVE FORCE"                                                                          ; process_arg "Shared"      ; return ; fi
            if test_arg "State"       ; then values="UP DOWN DRAIN INACTIVE"                                                                          ; process_arg "State"       ; return ; fi
            # If all the above did not match, a named argument has been partially entered; serve the list of arguments with no example values and do not append a trailing space
            COMPREPLY=( $( compgen -W "$(sed 's/\=[^ ]*/\=/g' <<< $create_partition_options)" -- $cur ) ) ; compopt -o nospace; return
            ;;
        reservation)
            local create_reservation_options="Reservation=<name> Users=<user_list> NodeCnt=<count> Nodes=<node_list> StartTime=YYYY-MM-DD[THH:MM[:SS]] EndTime=YYYY-MM-DD[THH:MM[:SS]] Duration=[days-]hours:minutes:seconds  Flags=MAINT,OVERLAP,IGNORE_JOBS,DAILY,WEEKLY PartitionName=<partition_list> Features=<feature_list> Accounts=<account_list> Licenses=<license>"
            # If a new named argument is about to be entered, serve the list of options
            remainingoptions=""
            for i in $create_reservation_options; do
                [[ "${COMP_WORDS[@]}" =~ ${i%%=*} ]] && continue 
                remainingoptions="$i $remainingoptions"
            done
            [[ $cur == "" && $prev != "=" ]] && { COMPREPLY=( $( compgen -W "${remainingoptions}" -- $cur ) ) ; return ; }
            # Test all potential arguments and server corresponding values
            if test_arg "Accounts" ; then values=$(sacctmgr -pn list accounts | cut -d'|' -f1 | paste -s -d' ')                                         ; process_arg "Accounts" ; return ; fi
            if test_arg "Licences" ; then values=$(scontrol show config| grep Licenses | sed 's/Licenses *=//'| paste -s -d' ')                         ; process_arg "Licences" ; return ; fi
            if test_arg "Nodes"    ; then values=$(scontrol show nodes | grep NodeName | cut -c 10- | cut -f 1 -d' ' | paste -s -d ' ')                 ; process_arg "Nodes"    ; return ; fi
            if test_arg "Features" ; then values=$(scontrol -o show nodes | cut -d' ' -f7 | sed 's/Features=//'  | sort -u | tr -d '()' | paste -d, -s) ; process_arg "Features" ; return ; fi
            if test_arg "Users"    ; then values=$(sacctmgr -pn list users | cut -d'|' -f1)                                                             ; process_arg "Users"    ; return ; fi
            if test_arg "Flags"    ; then values="MAINT OVERLAP IGNORE_JOBS DAILY WEEKLY"                                                               ; process_arg "Flags"    ; return ; fi
            # If all the above did not match, a named argument has been partially entered; serve the list of arguments with no example values  and do not append a trailing space
            COMPREPLY=( $( compgen -W "$(sed 's/\=[^ ]*/\=/g' <<< $remainingoptions)" -- $cur ) ) ; compopt -o nospace; return
            ;;
        esac
        ;;
    esac

    COMPREPLY=( $(compgen -W "${subopts}" -- $cur) )
}
complete -F _scontrol scontrol

_squeue()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    local subopts=""

    local shortoptions="   -a -h       -l                -s          -V -v   "
    local shortoptwarg="-A       -i -j    -M -n -o -p -q -s -S -t -u       --"
    local longoptions="--help --hide --steps --start --usage --verbose --version"
    local longoptwarg="--iterate= --jobs= --clusters= --nodes= --format= --partition= --qos= --sort= --states= --user="

    # Options
    if [[ "${cur:0:2}" == -- ]]; then
        COMPREPLY=( $( compgen -W "${longoptions} ${longoptwarg}" -- $cur ) )
        # If the completion ends with '=' do not add the trailing space
        if [[ ${COMPREPLY: -1} == "=" ]] ; then compopt -o nospace; fi
        return
    elif [[ "${cur:0:1}" == - ]]; then
        COMPREPLY=( $( compgen -W "${shortoptions} ${shortoptwarg}" -- $cur ) )
        return
    fi

    if test_arg "--user" ; then values=$(sacctmgr -pn list users | cut -d'|' -f1)                                         ; process_arg "--user" ; return ; fi

    COMPREPLY=( $(compgen -W "${subopts}" -- $cur) )
}
complete -F _squeue squeue

# vim: sw=4:ts=4:expandtab:fdm=indent
