file=.circleci/config.yml
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)

create_release_branch(){
    branch=release/$new_ver
    git checkout develop
    git pull
    git checkout -b $branch
    sed -i '' 's/default:.*/default: '\"$new_ver\"'/' $file
    git add .
    git commit -m "Update version name to $new_ver"
    git push --set-upstream origin $branch
}

list_branches_with_prefix(){
    prefix='feature'
    git branch -a | grep $prefix
}

PS3="Please choose an option: "
options=("Create release branch" "Merge release branch" "Quit")
select opt in "${options[@]}"
do 
   case $opt in
        "Create release branch")
            # Read the version name
            cur_ver=$(awk '$1=="default:"{print $2}' $file)
            # Stripped the quotes
            stripped_cur_ver=$(sed -e 's/^"//' -e 's/"$//' <<<"$cur_ver")
            # Prompt the user for the version name
            read -p "Enter version name (current: $stripped_cur_ver): " new_ver
            echo "==========================================="
            # Create release branch w/ new version name
            create_release_branch
            echo "${GREEN}Done${NC}"
            break
            ;;
        "Merge release branch")
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
   esac
done
