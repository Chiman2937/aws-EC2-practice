interface Props {
	params: Promise<{number: string}>
}

const RoutePage = async ({params}: Props) => {
	const {number} = await params;
	return (
		<div>{number}</div>
	)
}

export default RoutePage;