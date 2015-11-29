@echo Creating ModPacker script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.ModPacker %%1 %%2 > ModPacker.cmd
@echo Creating ModUnpacker script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.ModReader %%1 %%2 > ModUnpacker.cmd
@echo Creating ModToXml script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.ModToXml %%1 %%2 > ModToXml.cmd
@echo Creating GffToXml script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.GffToXml %%1 %%2 > GffToXml.cmd
@echo Creating XmlToGff script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.XmlToGff %%1 %%2 > XmlToGff.cmd
@echo Creating MiniMapExport script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool @java -cp @cwd@\nwn-tools.jar org.progeeks.nwn.MiniMapExporter %%1 %%2 > MiniMapExport.cmd
@echo Creating setpath script.
@java -cp nwn-tools.jar org.progeeks.util.PathTool set PATH=%%PATH%%;@cwd@ > setpath.cmd
@echo Done.

