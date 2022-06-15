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

merge_release_into_master(){
    git checkout main -q
    git pull -q

    prefix='release'
    # Get all branches with prefix
    release_branch=$(git branch -a | grep $prefix)

    # Exit if there's no release branch
    if [ -z "$release_branch" ]; then
        echo "No release branch found"
        exit 1
    fi

    # Get first release branch
    first_release=$(echo $release_branch | sed 's/ .*//')

    # Prompt user to confirm
    echo "Merge ${GREEN}$first_release${NC} into master?"
    select opt in "Yes" "No"; do
        case $opt in
            Yes)
                git checkout $first_release -q
                git pull -q
                git checkout main -q
                git merge --no-ff $first_release -m "Merge $first_release into master" -q
                git push -q
                echo "${GREEN}Done${NC}"
                break;;
            No ) 
                exit;;
            *) echo "invalid option $REPLY";;
        esac
    done
}


post_release(){
    read -p "Enter version name for tag: " tag_ver
    
    echo "Creating tag ${RED}$tag_ver${NC}......\c"
    git switch main -q
    git pull -q
    git tag $tag_ver
    git push origin $tag_ver -q
    echo "${GREEN}Done${NC}"

    echo "Merging master into dev......\c"
    git switch dev -q
    git pull -q
    git merge --no-ff main -m "Merge master into develop" -q
    git push -q
    echo "${GREEN}Done${NC}"
}

PS3="Please choose an option: "
options=("Create release branch" "Merge release branch" "Perform post-release" "Quit")
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
            merge_release_into_master
            break
            ;;
        "Perform post-release")
            post_release
            break;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
   esac
done
