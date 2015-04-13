# tcl_alto45_android_kitchen
Кухня для портирования сборок под Alcatel 5042D

Для того чтобы собрать порт, достаточно выполнить:

./build.sh SOURCE PRODUCT PRODUCT_VERSION [ADDONS]

Пример сборки CM11 с gapps и input-xperia:
./build.sh path_to_cm_source_rom.zip CM 11 gapps,input-xperia
Пример сборки MIUI 5.4.4 с input-xperia:
./build.sh path_to_miui_source_rom.zip MIUI 5.4.4 input-xperia

Скрипт распакует прошивку, удалит из нее мусор (что удалять указано в clean.txt, туда при необходимости можно добавить свое). 

Далее сформирует новый build.prop на основе оригинального + добавит информацию о сборке из исходной прошивки и заменит зависимости, необходимые для работы основных компонентов.

После работы скрипта в папке release появится готовый архив для установки через twrp или cwm.

По умолчанию система будет установлена в custpack, а не system, тк system слишком маленького объема! Для того, чтобы сделать прошивку, которая встанет в system, отредактируйте updater-script и заменить там все слова custpack на system.

Работа проверена на MIUI и CM11 от Redmi 2.

Принимаю реквесты с фиксами =)
