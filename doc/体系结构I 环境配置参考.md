# 体系结构I 环境配置参考

## Vivado 安装指引

（以下操作基于kubuntu 20.04 LTS）

1. 获取安装包(2018.2: https://jbox.sjtu.edu.cn/l/noXqCD )

2. 对于2018.2，使用gui安装即可；对于2020.1，执行以下命令

    ```
    sudo ./xsetup -b ConfigGen
    ```

    ```
    sudo ./xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config /root/.Xilinx/install_config.txt
    ```

    （第一条命令生成config，根据环境不同第二行命令中config路径可能不同，请参考第一行命令输出）

    一般通过执行/tools/Xilinx/Vivado/2020.1/bin/vivado来打开vivado

3. (Optional) 创建快捷方式：在~/Desktop/（桌面）或/usr/share/applications/（快捷启动）下建立`vivido.desktop`文件，内容为（以下为2020.1示例，2018.2自行对照，2018.2安装目录通常为/opt/而非/tools/）

    ```
    [Desktop Entry]
    Encoding=UTF-8
    Type=Application
    Name=Vivado 2020.1
    Comment=Vivado 2020.1
    Icon=/tools/Xilinx/Vivado/2020.1/doc/images/vivado_logo.png
    Exec={path to your launch script/exectuable}                                             
    ```

    （kde/gnome方法，不保证xfce下可用，若不可用建议自己查询对应方法）

### 可能问题

1. 出现如下错误

    ```
    terminate called after throwing an instance of 'std::runtime_error'
      what():  locale::facet::_S_create_c_locale name not valid
    /opt/Xilinx/Vivado/2016.4/bin/loader: line 179:  2309 Aborted                 (core dumped) "$RDI_PROG" "$@"
    ```

    解决方法：将环境改变至en_US

    在终端执行以下代码以改变环境变量

    ```
    export LC_ALL="en_US.UTF-8"
    ```

    若需要这样解决，通常需要创建launch script，并在script里执行export命令后再启动vivado

    

2. ```
    application-specific initialization failed: couldn't load file "librdi_commontasks.so": libtinfo.so.5: cannot open shared object file: No such file or directory
    ```

    解决方法：安装libtinfo-dev，再执行

    ```
    sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
    ```

3. 激活：使用vivado2037.llc

    使用方法见https://www.cnblogs.com/maskerk/p/7350182.html

