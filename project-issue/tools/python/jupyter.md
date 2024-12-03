# Jupyter Notebook issues
Jupyter Notebook 确保 IPython 内核可用，但您必须手动添加具有不同版本 Python 或虚拟环境的内核。首先，确保您的环境已使用 激活conda activate myenv。接下来，安装为 Jupyter 提供 IPython 内核的ipykernel ：
```shell
pip install --user ipykernel
```
接下来，您可以通过输入以下命令将虚拟环境添加到 Jupyter：
```shell
python -m ipykernel install --user --name=myenv
```
这应该打印以下内容：
```shell
Installed kernelspec myenv in /home/user/.local/share/jupyter/kernels/myenv
```
如果您正确完成所有操作，您将在此文件夹中找到一个kernel.json文件，其外观应如下所示：
```json
{
 "argv": [
  "/home/user/anaconda3/envs/myenv/bin/python",
  "-m",
  "ipykernel_launcher",
  "-f",
  "{connection_file}"
 ],
 "display_name": "myenv",
 "language": "python"
}
```