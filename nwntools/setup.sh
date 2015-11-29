#! /bin/sh
dir=$(pwd)

echo "Creating ModPacker script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.ModPacker \$1 \$2 > ModPacker
echo "Creating ModUnpacker script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.ModReader \$1 \$2 > ModUnpacker
echo "Creating ModToXml script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.ModToXml \$1 \$2 > ModToXml
echo "Creating GffToXml script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.GffToXml \$1 \$2 > GffToXml
echo "Creating XmlToGff script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.XmlToGff \$1 \$2 > XmlToGff
echo "Creating MiniMapExport script."
java -cp nwn-tools.jar org.progeeks.util.PathTool java -cp "$dir"/nwn-tools.jar org.progeeks.nwn.MiniMapExporter \$1 \$2 > MiniMapExport
echo "Creating setpath script."
java -cp nwn-tools.jar org.progeeks.util.PathTool export PATH=\$PATH:"$dir" > setpath.sh
echo "Done."

chmod +x ModPacker
chmod +x ModUnpacker
chmod +x ModToXml
chmod +x GffToXml
chmod +x XmlToGff
chmod +x MiniMapExport
chmod +x setpath.sh

