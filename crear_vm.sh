#!/bin/bash

# Función para mostrar el uso correcto del script
mostrar_uso() {
  echo "Uso: $0 <Nombre_VM> <Tipo_SO> <Num_CPUs> <RAM_GB> <VRAM_MB> <Tamaño_Disco_GB> <Nombre_Controlador_SATA> <Nombre_Controlador_IDE>"
  echo "Ejemplo: $0 MiVM Ubuntu_64 2 2048 128 50 SATA_Controller IDE_Controller"
  exit 1
}

# Verificar el número correcto de argumentos
if [ "$#" -ne 8 ]; then
  mostrar_uso
fi

# Asignación de argumentos
VM_NAME="$1"
OS_TYPE="$2"
CPUS="$3"
RAM="$4"
VRAM="$5"
HDD_SIZE="$6"
SATA_CONTROLLER="$7"
IDE_CONTROLLER="$8"

# Validar argumentos numéricos
if ! [[ "$CPUS" =~ ^[0-9]+$ ]] || ! [[ "$RAM" =~ ^[0-9]+$ ]] || ! [[ "$VRAM" =~ ^[0-9]+$ ]] || ! [[ "$HDD_SIZE" =~ ^[0-9]+$ ]]; then
  echo "Error: Los argumentos para CPUs, RAM, VRAM y Tamaño_Disco deben ser números enteros."
  mostrar_uso
fi

# Verificar si VirtualBox está instalado
if ! command -v VBoxManage &> /dev/null; then
  echo "Error: VirtualBox no está instalado. Por favor, instale VirtualBox y vuelva a intentarlo."
  exit 1
fi

# Crear la máquina virtual
if VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --register; then
  echo "Máquina virtual '$VM_NAME' creada con éxito."
else
  echo "Error: No se pudo crear la máquina virtual '$VM_NAME'."
  exit 1
fi

# Configurar recursos de hardware
VBoxManage modifyvm "$VM_NAME" --cpus "$CPUS" --memory "$((RAM * 1024))" --vram "$VRAM"

# Crear disco duro virtual
HDD_PATH="$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"
VBoxManage createhd --filename "$HDD_PATH" --size "$((HDD_SIZE * 1024))" --format VDI

# Crear y agregar el controlador SATA
VBoxManage storagectl "$VM_NAME" --name "$SATA_CONTROLLER" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "$SATA_CONTROLLER" --port 0 --device 0 --type hdd --medium "$HDD_PATH"

# Crear y agregar el controlador IDE para CD/DVD
VBoxManage storagectl "$VM_NAME" --name "$IDE_CONTROLLER" --add ide --controller PIIX4

# Mostrar la configuración final de la máquina virtual
VBoxManage showvminfo "$VM_NAME"