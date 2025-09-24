adb root
adb pull /data/data/de.tmc.splizz.debug/databases/my_repository.sqlite ./
#sqlitebrowser my_repository.sqlite
flatpak run --branch=stable --arch=x86_64 --command=sqlitebrowser --file-forwarding org.sqlitebrowser.sqlitebrowser @@ %f @@ my_repository.sqlite