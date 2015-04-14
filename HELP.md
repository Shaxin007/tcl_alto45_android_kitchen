#Быстрый старт
**Что необходимо:**

- Linux (можно в виртуалке)
- git
- руки, какие есть

**Ставим git**

OS            | Комманда установки
------------- | -------------
ubuntu        | #apt-get install git
red hat/centos| #yum install git
arch          | #pacman -S git

**Клонируем git репозиторий**

`git clone https://github.com/deadlink/tcl_alto45_android_kitchen.git ~/android_kitchen`

**Скачиваем прошивку-донор**

Ищем донора, качаем например [miuipro Redmi 2 WCDMA](http://miuipro.ru/rommgr/device_view/310/)

**Собираем порт (пути подставьте свои)**

`~/android_kitchen/build.sh ~/Загрузки/miuipro_v4.4.4_HM2014811_5.4.10.zip MIUI 5.4.10 input-xperia`

**После завершения**

- Заглядываем в папку ~/android_kitchen/release

- Копируем сборку на карту памяти

- Прошиваемся через рекавери

- Перезагружем телефон из рекавери, кабель остается подключенным

- Вводим в консоли `adb logcat`

- Смотрим лог процесса запуска 

**Завершение**

Если в логе вы не увидели проблем - ошибок и прочего, то поздравляю, ***Ваш порт готов***!




