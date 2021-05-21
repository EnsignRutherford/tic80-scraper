#!/bin/bash

# TIC-80 Software Downloader
#
# This script downloads TIC-80 cartridges from https://tic.computer
# Cartridges are downloaded and stored as .tic files in their respective category directory.
# The file name format is as follows:
#   ${cartridgeName}.tic

#############
# VARIABLES #
#############

releaseDate=2021.05.01

#############
# FUNCTIONS #
#############

# chooseCategory
#   asks the user which category of software they want to download and set it as ${categoryChoice}
function chooseCategory {
  PS3="Which category of software do you want to download? "
  select categoryChoice in Games Tech Tools Music WIP Demoscene "All categories"; do
    case ${categoryChoice} in
      Games|Tech|Tools|Music|WIP|Demoscene|"All categories") break;;
    esac
  done
}

# unescapeHTML
#   converts stdin HTML tags to plain text
function unescapeHTML {
  sed 's/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;/\"/g; s/&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g;'
}

# categoryId <categoryName>
#   outputs the category ID for a given category name
function categoryId {
  local categoryName="$1"
  case ${categoryName} in
    Games) echo 0;;
    Tech) echo 1;;
    Tools) echo 2;;
    Music) echo 3;;
    WIP) echo 4;;
    Demoscene) echo 5;;
    *) echo "Category not found"; break;;
  esac
}

# downloadCartridge <cartridgeId> <cartridgeName> <categoryName>
#   downloads a given cartridge
function downloadCartridge {
  local id=$1
  local name=$2
  local newname=${name:0:-1}
  name=${newname}
  local categoryName=$3
  local pageContent=$(curl -sL "https://tic80.com/play?cart=${id}")
  local hash=$(echo "${pageContent}" | sed -n 's|.*href="/cart/\(.*\)/cart.tic".*|\1|p')
  local createdAt=$(echo "${pageContent}" | sed -n 's|.*added: <span class="date" value="\([[:digit:]]*\)">.*|\1|p')
  local updatedAt=$(echo "${pageContent}" | sed -n 's|.*updated: <span class="date" value="\([[:digit:]]*\)">.*|\1|p')
  local timestamp=$(date -d @$((${updatedAt:-${createdAt}} / 1000)) +%F_%H-%M)
  echo -n "Downloading cartridge ${name} in ${categoryName}"
  mkdir -p ${categoryName}
  curl -sLf "https://tic80.com/cart/${hash}/cart.tic" \
    -o "${categoryName}/${name}.tic" \
    && echo " [OK]" \
    || echo " [ERROR]"
}

# downloadCategorySoftware <categoryName>
#   downloads all cartridges in a given category
function downloadCategorySoftware {
  local categoryName="$1"
  local categoryId=$(categoryId ${categoryName})
  local x=0
  while :
  do
	  local categoryPageContent=$(curl -sLf "https://tic80.com/play?cat=${categoryId}&sort=2&page=$x")
	  if [ "$categoryPageContent" == "" ]
	  then
	    break
          fi
	  IFS=$'\n'
	  local cartridgeNames=( $(echo "${categoryPageContent}" | sed -n 's|.*<h2>\(.*\)</h2>|\1|p' | unescapeHTML) )
	  local cartridgeIds=( $(echo "${categoryPageContent}" | sed -n 's|.*href="/play?cart=\([[:digit:]]*\)".*|\1|p') )
	  for (( i = 0; i < ${#cartridgeNames[@]}; i++ )); do
 	    downloadCartridge "${cartridgeIds[$i]}" "${cartridgeNames[$i]}" "${categoryName}"
	  done
          ((x=x+1))
  done
}

########
# MAIN #
########

echo "tic80-scraper ver. ${releaseDate}"

chooseCategory

if [ "${categoryChoice}" = "All categories" ]; then
  for category in Games Tech Tools Music WIP Demoscene; do
    downloadCategorySoftware ${category}
  done
else
  downloadCategorySoftware ${categoryChoice}
fi

