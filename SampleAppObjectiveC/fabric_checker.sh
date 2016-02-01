if [ -f ./fabric.sh ]; then
    echo "Using user provided Fabric info."
    ./fabric.sh
  else
    echo "No Fabric info provided."
    ./Fabric.framework/run _________No_Fabric_API_Key_Here_________ No_Build_Secret
fi