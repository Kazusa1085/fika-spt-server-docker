#!/bin/sh
set -eu

APP_DIR="/opt/spt"
USER_DIR="${APP_DIR}/user"
DEFAULTS="/opt/defaults-user"

# -----------------------------------------------------------------------------
# 首次运行：把镜像里的出厂 user 内容（含 Fika mod）填进挂载的卷
#
# 为什么需要这一步：基础镜像声明了 VOLUME /opt/spt/user，挂载的卷会遮住镜像
# 内容。不填充的话，Fika 会"消失"。
# `-n`（no-clobber）保证不会覆盖你已有的存档、账号、Mod。
# -----------------------------------------------------------------------------
if [ ! -e "${USER_DIR}/.initialized" ]; then
    echo "[init] 首次运行，正在初始化 user 目录..."

    mkdir -p "${USER_DIR}"

    if [ -d "${DEFAULTS}" ]; then
        cp -an "${DEFAULTS}/." "${USER_DIR}/" 2>/dev/null || true
    fi

    touch "${USER_DIR}/.initialized"

    if [ -f "${USER_DIR}/mods/fika-server/FikaServer.dll" ]; then
        echo "[init] Fika mod 已就位"
    else
        echo "[init] 警告：未找到 Fika mod，请检查镜像构建" >&2
    fi

    echo "[init] 初始化完成"
else
    echo "[init] user 目录已初始化，跳过"
fi

# 兜底：确保关键子目录存在（挂空的卷时）
mkdir -p "${USER_DIR}/mods" "${USER_DIR}/profiles" "${USER_DIR}/logs" "${USER_DIR}/certs" 2>/dev/null || true

# -----------------------------------------------------------------------------
# 交给官方 entrypoint：它负责
#   · 按 SPT_IP / SPT_PORT / SPT_BACKEND_IP / SPT_BACKEND_PORT 改写 http.json
#   · 按 PUID/PGID 调整 user 目录属主
#   · 用 gosu 降权启动 SPT.Server.Linux
# -----------------------------------------------------------------------------
exec /usr/local/bin/entrypoint.sh "$@"
