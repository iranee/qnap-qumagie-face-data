# QuMagie Face Metadata Backup Tool

## 项目简介

QuMagie 版本 v2.4.0 支持了人脸识别元数据的备份和恢复，但目前每次备份仍需通过网页端手动操作。为了简化这一过程，我编写了一个基于 QuMagie 备份程序代码的自定义备份命令工具。这款工具能够自动化备份操作，不再需要每次都手动进行备份。
此命令工具是基于QuMagie安装目录的CLI文件 qumagie/v2.4.0/cli/qm_export 提取的相关运行命令，不会对原文件进行更改。

## QuMagie 元数据备份机制

在之前的文章中，我介绍过通过备份 MySQL 相册数据 `S01` 库来实现人脸识别数据的备份。在 QTS 旧版本中，这种方法能够正常导入和识别。然而，在 QTS 5.0 及以上版本的更新，系统会自动重新索引数据，导致已导入的数据丢失，并且人脸识别数据被重新识别。

这次 QuMagie 新发布的版本采用了新的备份原理：将每张图片或视频的元数据保存为 JSON 文件。每次备份时，系统会生成一个对应的 JSON 文件，并将其存储在照片文件夹下的隐藏目录 `. @__thumb` 中，文件名与照片或视频文件名一致，后缀为 `.json`。这个 JSON 文件包含了照片和视频的详细元数据、相册 ID、人脸识别信息等重要数据。

### JSON 文件结构示例内容：

每个备份的 JSON 文件都包含了与图片或视频相关的所有元数据。以下是一个 JSON 文件的示例：

```json
{
    "MediaType": "photo",
    "Path": "/share/Photo/全家福/01.jpg",
    "Title": "01 (17)",
    "Comment": "null",
    "Keywords": "null",
    "ColorLevel": "0",
    "Longitude": "null",
    "Latitude": "null",
    "Time": "2022-07-15 18:30:56",
    "Favorite": "0",
    "Rating": "0",
    "Objects": [
        {
            "object": {
                "id": "k2jlff",
                "name": "Wedding"
            }
        },
        {
            "object": {
                "id": "GtGVc0",
                "name": "Person"
            }
        },
        {
            "object": {
                "id": "tCyPUP",
                "name": "Clothing"
            }
        },
        {
            "object": {
                "id": "kwg2xK",
                "name": "Wedding dress"
            }
        },
        {
            "object": {
                "id": "bdoUmX",
                "name": "Bride"
            }
        }
    ],
    "Faces": [
        {
            "face": {
                "name": "爸爸",
                "FaceId": "HmPbzl",
                "X": "201",
                "Y": "105",
                "Width": "136",
                "Height": "152",
                "GroupId": "cTinsP",
                "iFaceCover": "M92WZX"
            }
        },
        {
            "face": {
                "name": "妈妈",
                "FaceId": "tu1TsA",
                "X": "295",
                "Y": "285",
                "Width": "121",
                "Height": "160",
                "GroupId": "TGcDVc",
                "iFaceCover": "t0Ys2S"
            }
        }
    ],
    "Albums": [],
    "Qtag": "32febe21201f4fbfb94d02b58d15b3972ec9d78803e5",
    "DataVersion": "1.0"
}
```
### 使用方法
将`qumagie-backup.sh`文件上传到你的 QNAP 设备中，并赋予0755系统权限。

编辑`qumagie-backup.sh`代码，填入相关的备份用户名以及保存地址。
关键数据是第10-13行，
```
export_type="metadata"   
可选：metadata ，仅元数据。表示从帐户导出元数据(例如相册、标签、人物等)
可选：full，文件和元数据。从帐户导出媒体文件和元数据(例如相册、标签、人物等)

target_folder="备份/照片备份/QuMagie"
 备份路径，是在/share/目录下的文件夹，所以前戳不需要再加/share/路径

uname="admin"
当前用户名，如果是最高权限管理员，可以备份其他用户的数据。

password=""
可选密码。为空则密码为系统默认`qnapqnap`，如果这里设置为`123456`，则密码为`qanpqnap123456`
```
