package utils

import (
	"encoding/json"
	"reflect"
	"strconv"
	"strings"
	"time"
)

// ==================== 时间工具 ====================

// Now 返回当前时间
func Now() time.Time {
	return time.Now()
}

// FormatTime 格式化时间为 Y-m-d H:i:s
func FormatTime(t time.Time) string {
	return t.Format("2006-01-02 15:04:05")
}

// FormatDate 格式化日期为 Y-m-d
func FormatDate(t time.Time) string {
	return t.Format("2006-01-02")
}

// ParseTime 解析 Y-m-d H:i:s 格式字符串为 time.Time
func ParseTime(s string) (time.Time, error) {
	return time.ParseInLocation("2006-01-02 15:04:05", s, time.Local)
}

// TimeAgo 返回相对时间描述（例如 "5分钟前"）
func TimeAgo(t time.Time) string {
	diff := time.Since(t)
	seconds := int(diff.Seconds())
	if seconds < 60 {
		return strconv.Itoa(seconds) + "秒前"
	}
	minutes := seconds / 60
	if minutes < 60 {
		return strconv.Itoa(minutes) + "分钟前"
	}
	hours := minutes / 60
	if hours < 24 {
		return strconv.Itoa(hours) + "小时前"
	}
	days := hours / 24
	if days < 30 {
		return strconv.Itoa(days) + "天前"
	}
	months := days / 30
	if months < 12 {
		return strconv.Itoa(months) + "个月前"
	}
	years := months / 12
	return strconv.Itoa(years) + "年前"
}

// ==================== 字符串工具 ====================

// Trim 去除字符串两端空白
func Trim(s string) string {
	return strings.TrimSpace(s)
}

// IsEmpty 判断字符串是否为空
func IsEmpty(s string) bool {
	return len(strings.TrimSpace(s)) == 0
}

// Substring 安全的字符串截取
func Substring(s string, start, end int) string {
	if start < 0 {
		start = 0
	}
	runes := []rune(s)
	if end > len(runes) || end < 0 {
		end = len(runes)
	}
	if start >= end {
		return ""
	}
	return string(runes[start:end])
}

// Reverse 反转字符串
func Reverse(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

// Capitalize 将字符串首字母大写
func Capitalize(s string) string {
	if len(s) == 0 {
		return s
	}
	runes := []rune(s)
	if runes[0] >= 'a' && runes[0] <= 'z' {
		runes[0] = runes[0] - 32
	}
	return string(runes)
}

// ==================== 数字工具 ====================

// Min 返回较小的整数
func Min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// Max 返回较大的整数
func Max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// Abs 返回整数的绝对值
func Abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

// AbsInt64 返回int64的绝对值
func AbsInt64(n int64) int64 {
	if n < 0 {
		return -n
	}
	return n
}

// IntToStr 将 int 转为字符串
func IntToStr(n int) string {
	return strconv.Itoa(n)
}

// StrToInt 将字符串转为 int, 失败返回默认值
func StrToInt(s string, defaultValue int) int {
	n, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil {
		return defaultValue
	}
	return n
}

// StrToInt64 将字符串转为 int64, 失败返回默认值
func StrToInt64(s string, defaultValue int64) int64 {
	n, err := strconv.ParseInt(strings.TrimSpace(s), 10, 64)
	if err != nil {
		return defaultValue
	}
	return n
}

// ==================== 验证工具 ====================

// IsValidUsername 验证用户名是否合法：3-20位字母数字或中文
func IsValidUsername(s string) bool {
	s = strings.TrimSpace(s)
	if len(s) < 3 || len(s) > 20 {
		return false
	}
	for _, r := range s {
		if !(r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9' || r >= 0x4e00 && r <= 0x9fa5 || r == '_') {
			return false
		}
	}
	return true
}

// IsStrongPassword 验证密码强度：至少8位，包含字母和数字
func IsStrongPassword(s string) bool {
	if len(s) < 8 {
		return false
	}
	hasLetter := false
	hasDigit := false
	for _, r := range s {
		if r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' {
			hasLetter = true
		}
		if r >= '0' && r <= '9' {
			hasDigit = true
		}
	}
	return hasLetter && hasDigit
}

// ==================== 切片工具 ====================

// Contains 判断切片是否包含某元素（string）
func ContainsString(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// ContainsInt 判断切片是否包含某元素（int）
func ContainsInt(slice []int, item int) bool {
	for _, n := range slice {
		if n == item {
			return true
		}
	}
	return false
}

// UniqueStrings 去除字符串切片中的重复元素
func UniqueStrings(slice []string) []string {
	seen := map[string]bool{}
	result := make([]string, 0, len(slice))
	for _, s := range slice {
		if !seen[s] {
			seen[s] = true
			result = append(result, s)
		}
	}
	return result
}

// JoinInts 将 int 切片用分隔符连接为字符串
func JoinInts(ints []int, sep string) string {
	strs := make([]string, len(ints))
	for i, n := range ints {
		strs[i] = strconv.Itoa(n)
	}
	return strings.Join(strs, sep)
}

// ==================== JSON / Map 工具 ====================

// ToJSON 将任意对象转为 JSON 字符串
func ToJSON(v interface{}) (string, error) {
	data, err := json.Marshal(v)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// ToJSONPretty 将任意对象转为格式化的 JSON 字符串
func ToJSONPretty(v interface{}) (string, error) {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// FromJSON 从 JSON 字符串解析到目标对象
func FromJSON(s string, out interface{}) error {
	return json.Unmarshal([]byte(s), out)
}

// ==================== 反射 / 默认值 工具 ====================

// SetDefault 如果目标字段为空，则设置默认值
func SetDefault(target *string, defaultValue string) {
	if target == nil {
		return
	}
	if IsEmpty(*target) {
		*target = defaultValue
	}
}

// SetDefaultInt 如果目标为0，则设置默认值
func SetDefaultInt(target *int, defaultValue int) {
	if target == nil {
		return
	}
	if *target == 0 {
		*target = defaultValue
	}
}

// IsZero 判断任意值是否为零值
func IsZero(v interface{}) bool {
	if v == nil {
		return true
	}
	rv := reflect.ValueOf(v)
	switch rv.Kind() {
	case reflect.String:
		return rv.Len() == 0
	case reflect.Array, reflect.Map, reflect.Slice:
		return rv.Len() == 0
	case reflect.Bool:
		return !rv.Bool()
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return rv.Int() == 0
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return rv.Uint() == 0
	case reflect.Float32, reflect.Float64:
		return rv.Float() == 0
	case reflect.Ptr, reflect.Interface:
		return rv.IsNil()
	}
	return false
}

// ==================== 游戏工具 ====================

// FormatMesos 格式化冒险岛金币（千分位分隔）
func FormatMesos(n int64) string {
	negative := n < 0
	if negative {
		n = -n
	}
	s := strconv.FormatInt(n, 10)
	chunks := make([]string, 0, (len(s)+2)/3)
	for len(s) > 3 {
		chunks = append([]string{s[len(s)-3:]}, chunks...)
		s = s[:len(s)-3]
	}
	chunks = append([]string{s}, chunks...)
	result := strings.Join(chunks, ",")
	if negative {
		return "-" + result
	}
	return result
}

// MaskUsername 对用户名进行隐藏处理（中间用*替换）
func MaskUsername(name string) string {
	runes := []rune(name)
	if len(runes) <= 1 {
		return name
	}
	if len(runes) == 2 {
		return string(runes[0]) + "*"
	}
	mid := len(runes) / 2
	start := mid - 1
	end := mid + 1
	if len(runes) > 5 {
		start = 1
		end = len(runes) - 1
	}
	result := make([]rune, len(runes))
	for i := range runes {
		if i >= start && i < end {
			result[i] = '*'
		} else {
			result[i] = runes[i]
		}
	}
	return string(result)
}

// ==================== 协程安全工具 ====================

// SafeGo 安全地启动一个协程（有 panic recover）
func SafeGo(fn func()) {
	go func() {
		defer func() {
			_ = recover()
		}()
		fn()
	}()
}

// ==================== 版本工具 ====================

// CompareVersion 比较两个 x.y.z 版本号，返回 1 if a>b, -1 if a<b, 0 if equal
func CompareVersion(a, b string) int {
	aParts := strings.Split(a, ".")
	bParts := strings.Split(b, ".")
	for i := 0; i < len(aParts) || i < len(bParts); i++ {
		av := 0
		bv := 0
		if i < len(aParts) {
			av, _ = strconv.Atoi(aParts[i])
		}
		if i < len(bParts) {
			bv, _ = strconv.Atoi(bParts[i])
		}
		if av > bv {
			return 1
		}
		if av < bv {
			return -1
		}
	}
	return 0
}
